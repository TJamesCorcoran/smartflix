# THIS FILE: newsletter/lib/do.rb  <--- NEWSLETTER

# The class
#     JobRunner::Do
# gets opened and redefined multiple times.
#     * base        lib/job_runner/lib/do.rb
#     * newsletter  lib/newsletter_editor/lib/do.rb
#     * heavyink    lib/job_runner_hi/do.rb

module JobRunner
  class Do

    # this is the entry point for a general sending
    # 
    def self.newsletter_emailer
      deliver_all(ENV['NEWSLETTER'], ENV['EMAIL_ADDR_OVERRIDE'])
    end

    private

    def self.deliver_all(id, email_addr_override = nil)
      @newsletter = Newsletter.find(id)
      @newsletter.reset if Rails.env == 'development' && ENV['RESET'] == 'true'
      @newsletter.update_attribute(:kill, false)
      
      customers = []
      check_permissions = true
      
      if email_addr_override
        customers = [ Customer.new(:email => email_addr_override) ]
        check_permissions = false
      else
        customers = eval(@newsletter.newsletter_category.code)
      end
      
      # some  
      #
      customers.reject! { |c| c.email.match(/invalid|spammer/) }
      
      customers = customers[0..5] if Rails.env != 'production'
      
      @newsletter.update_attributes :total_recipients => customers.size
      
      customers.each do |customer|
        
        # had the admin killed this send process?
        #
        check_kill_newsletter(@newsletter)
        
        # did we already send this?
        #
        recip = customer.newsletter_recipients.find_by_newsletter_id(@newsletter.id)
        next failure(:already_sent,customer) if recip && recip.status == 'sent'
        
        # are we allowed to send it?
        #
        next failure(:not_allowed,customer) unless check_permissions == false || customer.send_newsletter_email? 
        
        recip ||= NewsletterRecipient.create(:newsletter => @newsletter, :customer => customer, :status => "unsent")
        
        # send it
        #
        deliver_one(customer,recip)
      end
      
      log "Complete."
    end

    #  Actually send the emails.  
    # 
    #  Runs check_kill_newsletter between each send to allow for
    #  quick killing if necessary.  If we're not in production
    #  mode, it changes the email of every customer to
    #  EMAIL_TO_DEVELOPER.  It also runs a utility for switching
    #  the url of images for each email.
    #
    #  Inputs:
    #     * customer -
    #     * recip -
    def self.deliver_one(customer,recip,override=false)
      check_kill_newsletter(@newsletter)
      begin
        deliver_addr = customer.email
        if Rails.env != 'production' || ENV['TEST'] == "true"
          deliver_addr = (Rails.application.class)::EMAIL_TO_DEVELOPER unless override
        end
        #                           where to            nominally to   what
        #                           (maybe developer)
        #-------------------------------------------------------------------------
        ::NewsletterMailer.newsletter(deliver_addr,       customer,      @newsletter)
      rescue Timeout::Error
        log "TIMED_OUT: #{customer.email}"
        # RAILS3            redo
      rescue => error
        failure(:failed_to_send,customer,recip,error)
      else
        success(customer, recip)
      end
    end
    



    def self.log(text)
      JobRunner::LOGGER.info text
    end
    
    def self.failure(type,customer,recip=nil,error=nil)
      log "#{type.to_s.upcase}: #{customer.email}"
      log "FAILURE MODE: #{error}" if error
      recip.update_attributes(:status => type.to_s) if recip
    end
    
    def self.success(customer, recip)
      log "SENT: #{customer.email}"
      recip.update_attributes :status => 'sent'
    end
    
    
    # Checks the newsletter database record to see if kill has been set to true
    #  and aborts if so
    def self.check_kill_newsletter(newsletter)
      newsletter.reload
      exit if newsletter.kill?
    end
    

  end
end


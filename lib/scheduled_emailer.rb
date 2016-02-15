#  
#
#

class ScheduledEmailer

  MIN_DAYS_BETWEEN_EMAILS = 14

  @@logger = method(:puts)   
  cattr_accessor :logger


  #----------
  # level 4
  #----------


  # recruit people to univs
  #
  #
  #  a general function which
  #     - iterates over customers
  #     - rejects some
  #     - gets a reco for each
  #     - sends an email
  #     - notes that the email was sent
  #
  def self.univ_emails_INTERNAL(customers, 
                                skip_func, 
                                reco_func, 
                                scheduled_mail_type, 
                                mailer_function)
    verbose = ! Rails.env.production?

    limit = ENV['SEND_LIMIT'] ? (ENV["SEND_LIMIT"].to_i) : customers.size / 20
    limit = 5 unless Rails.env.production?

    @@logger.call "#{customers.size.commify} customers selected"
    @@logger.call "#{limit.commify} limit"

    count = 0

    over = rejected  = skip = error  = sent = 0
   
    customers.each do |customer| 

      # (1) overall count
      #
      count += 1
      if count >= limit
        over += 1
        @@logger.call "* over limit #{limit}" if verbose
        break
      end

      # (2) generic reject (bounced, recent email, cust too new, etc.)
      #
      @@logger.call "* [#{Time.now.strftime('%F %T')}] cust == #{customer.email}" if verbose

      last_sched_email = customer.sorted_scheduled_emails.first
      if reject_customer?(customer,last_sched_email)
        rejected += 1
        @@logger.call "cust #{sprintf('%8i', customer.id)}  - rejected generic" if verbose
        next
      end

      # (3) mode-specified reject
      #
      if skip_func && skip_func.call(customer)
        skip += 1
        @@logger.call "cust #{sprintf('%8i', customer.id)}  - rejected specific" if verbose
        next
      end

      # (4) send email
      #
      univ_reco = reco_func.call(customer)
      @@logger.call "cust #{sprintf('%8i', customer.id)} gets univ reco #{sprintf('%30s', univ_reco.name)}" if verbose
      begin
        SfMailer.send(mailer_function, customer, univ_reco)
        ScheduledEmail.create(:customer => customer, :product => univ_reco, :email_type => scheduled_mail_type)
        sent += 1
      rescue Exception=>e
        ExceptionNotifier::Notifier.exception_notification({}, e).deliver
        error += 1
      end

    end

    @@logger.call "skipped bc over-quantity:   #{over.commify}"
    @@logger.call "skipped bc generic  filter: #{rejected.commify}"
    @@logger.call "skipped bc specific filter: #{skip.commify}"
    @@logger.call "error:                      #{error.commify}"
    @@logger.call "sent:                       #{sent.commify}"

    
  end

  #----------
  # level 3 (call-backs from level 4)
  #----------


  # for a given customer, what univ should we recommend to them?
  #
  def self.recruit_new_RECO_FUNC(customer)
    
    # (1) pick all possible univs
    #
    univ_recos = (customer.univs_by_rented + customer.univs_by_browsed_categories + University.most_popular).flatten.uniq
    
    # (2) which one of these do we recommend today?  The one
    # that's been recommended the furthest back in time.
    #
    prev_emails = customer.scheduled_emails.select { |se| se.email_type == "univ_reco" }
    prev_emails = prev_emails.map { |se| [ se.product, se.created_at] }.to_h
    
    univ = univ_recos.min_by { |univ| prev_emails[univ] || DateTime.parse("1900-01-01") }
  end

  # given an old univ customer who is no longer active, invite them back
  #
  def self.recruit_old_RECO_FUNC(customer)

    # (1) pick all possible univs - those that this cust once subscribed to
    #
    # NOTE: this is inefficient, bc we already computed this information up above.  :-(
    #
    univ_recos = customer.univ_orders.select {|o| o.univ_status == :live_unpaid }.map(&:university)
    
    # (2) which one of these do we recommend today?  The one
    # that's been recommended the furthest back in time.
    #
    prev_emails = customer.scheduled_emails.select { |se| se.email_type == "univ_old_cust" }
    prev_emails = prev_emails.map { |se| [ se.product, se.created_at] }.to_h

    
    univ = univ_recos.min_by { |univ| prev_emails[univ] || DateTime.parse("1900-01-01") }
    univ

  end


  # return
  #     true - skip
  #     false - go ahead and send
  def self.recruit_new_SKIP_FUNC(customer)
    return customer.univ_orders_live.any?
  end

  def self.recruit_old_SKIP_FUNC(customer)
    # note: not exactly the same thing as asking
    return customer.univ_orders.map(&:univ_status).detect { |x| x == :live }.to_bool
  end


  #----------
  # level 2
  #----------

  # find customers who DO NOT yet sub to a univ and send them email inviting them
  #
  def self.recruit_new_univ_customers
    univ_emails_INTERNAL(Customer.all,
                         ScheduledEmailer.method(:recruit_new_SKIP_FUNC), 
                         ScheduledEmailer.method(:recruit_new_RECO_FUNC), 
                         "univ_new_cust",   # email type
                         "univ_new_cust")   # mailer function
  end

  # find customers who ONCE DID sub to a univ and send them email asking them back
  #
  def self.recruit_old_univ_customers


    customers = Order.for_univ_any.select {|o| [ :live_unpaid ].include?(o.univ_status) }.map(&:customer).uniq

    univ_emails_INTERNAL(customers,
                         ScheduledEmailer.method(:recruit_old_SKIP_FUNC), 
                         ScheduledEmailer.method(:recruit_old_RECO_FUNC), 
                         "univ_old_cust",   # email type
                         "univ_old_cust")   # mailer function
  end

  #----------
  # level 1
  #----------
  def self.recruit_univ_customers
    recruit_new_univ_custs
  end

  #-----
  # every customer browses items - remind them of what they looked at
  #-----
  def self.email_about_browsed_items

    @@logger.call "Finding all customers... [#{Time.now.strftime('%F %T')}]"
    
    # it's quicker to group by customer _id, then map to customers
    cust_ids_to_urltracks = UrlTrack.last_24_hrs.with_customer.group_by(&:customer_id)
    custs_to_urltracks = cust_ids_to_urltracks.map { |k, v| [ Customer[k], v ]}.to_h

    customers = custs_to_urltracks.keys
    unless Rails.env == 'production'
      count = 10
      customers = customers[0,count]  || []
      @@logger.call " ... truncating to #{count} in non-production mode"
    end


    @@logger.call "Sending... [#{Time.now.strftime('%F %T')}]"
    customers.each do |cust|
      
      # note that we're iterating over a hash, but we're going to ignore the value

      if ! cust.send_email_of_type?("recommended") 
        @@logger.call " * skipping (no permission) - #{cust.email}"
        next
      end
      
      # base recos
      browsed = cust.browsed_but_not_rented_or_recoed
      if browsed.empty?
        @@logger.call " * skipping (no browsing) - #{cust.email}"
        next
      end
      browsed_by_cat = browsed.group_by { |product| product.categories.first }
      
      # prune down to just 3 cats, 2 prods per cat
      good_keys = browsed_by_cat.keys[0,2]
      browsed_by_cat = browsed_by_cat.map{|key,val| good_keys.include?(key) ? [key,val] : [] }.reject{|key,val| key.nil?}.to_hash
      browsed_by_cat = browsed_by_cat.map {|cat, products| [cat, products[0,2]]}.to_hash
      
      
      # XXX says "add other recos - less creepy than just 'we spy on you!'"
      other_by_cat = Hash.new { |hash, key| hash[key] = Array.new }
      browsed_by_cat.keys.each do |cat|
        other_by_cat[cat] = cust.toprated_but_never_rented(cat) - browsed_by_cat[cat]
      end
      other_by_cat = other_by_cat.map {|cat, products| [cat, products[0,1]]}.to_hash
      
      rent_token = OnepageAuthToken.create_token(cust, 10, :controller => 'cart', :action => 'checkout')
      
      begin
        @@logger.call "    * #{cust.id} - #{cust.email} - about to send email"
        
        SfMailer.browsed( :customer => cust,
                                :browsed_titles_by_cat => browsed_by_cat,
                                :toprated_titles_by_cat => other_by_cat,
                                :token => rent_token,
                                :ctcode => "browsed")
        
        full_list = browsed_by_cat.map {|key,val| val }.flatten +  other_by_cat.map {|key,val| val }.flatten
        full_list.each do |product|
          ScheduledEmail.create(:customer => cust,
                                :product => product,
                                :email_type => "browsed")
        end
      rescue 
        @@logger.call "error: #{$!.inspect}" 
      end
    end
  end

  #----------
  # utility functions
  #----------
  
  # should we reject this customer?
  #
  #
  def self.reject_customer?(customer, last_email, verbose = false)
    
    # Removes bounced email customers
    #
    if customer.emailBouncedP?
      @logger.debug "Skipping customer #{customer.id} because their email bounced in the past" if verbose
      return true
    end
    
    # Removes customers who have received the email < 17 days ago
    #
    if customer.sorted_scheduled_emails && last_email && last_email.created_at.to_time > MIN_DAYS_BETWEEN_EMAILS.days.ago
      @logger.debug "Skipping customer #{customer.id} because they received another one < #{MIN_DAYS_BETWEEN_EMAILS} days ago" if verbose
      return true
    end
    
    # Don't email customer if they placed their first order in the past month
    #
    firstOrder = customer.firstOrderDate
    if (firstOrder != nil && Date.today - firstOrder < 30)
      @logger.debug "Skipping customer #{customer.id} because they are new" if verbose
      return true
    end

    # Don't email customer if they placed their first order in the past month
    #
    firstOrder = customer.firstOrderDate
    if (firstOrder != nil && Date.today - firstOrder < 30)
      @logger.debug "Skipping customer #{customer.id} because they are new" if verbose
      return true
    end
  end



end

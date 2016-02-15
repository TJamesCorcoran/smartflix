# THIS FILE: job_runner_SF/lib/do.rb  <--- SMARTFLIX

# The class
#     JobRunner::Do
# gets opened and redefined multiple times.
#     * base        lib/job_runner/lib/do.rb
#     * newsletter  lib/newsletter/lib/do.rb
#     * smartflix   lib/job_runner_sf/do.rb


module JobRunner
  
  class Do

    #==========
    # Newsletter sender.  This is normally run via a web interface, but can be called like so...
    #   ex.: ruby bin/job_runner.rb do newsletter_emailer NEWSLETTER=5
    #
    #   NEWSLETTER - integer id of the newsletter you want to send
    #   TEST - 'true' - end all emails to TVR_DEVELOPER_EMAIL (blog posts and image push may still
    #          be done based upon the Rails.env variable)
    #
    # Actually, the code doesn't lie here ... it lies in 
    #     ../vendor/plugins/newsletter_editor/lib/newsletter_editor/job.rb
    # where it monkey patches Job::Do
    #
    #     'newsletter_emailer'
    #==========

    # XYZFIX P3 - duplicate code in SF and HI - move this into a plugin?
    #
    DEVEL = Rails.env.development?

    #---- frontend
    FRONTEND_DB_DIR    = DEVEL ? "/tmp/" : "/backup/db/"  
    FRONTEND_URL       = "'smartflix.com:/backup/db/*'"
    DB_NAME            = "smart_railscart"
    SSH_USER           =  "smart"    

    #---- backend backups                 # on NEON - would be nice to move this to /share
    BACKEND_DB_DIR     = DEVEL ? "/tmp/" : "/home/autorun/external-db-backups/"
    FILE_STUB          = DEVEL ? "railscart_development"  : "smart_railscart"

    #---- scrubbed copy for devel use
    SCRUBBED_NAME         = "sfw_scrubbed.sql.gz"
    
    SmartFlix::Application::BACKEND_CLEAN_DIR  = DEVEL ? "/tmp/" : "/share/development_databases/"
    

    def self.db_filename(logger = Rails.Logger, date = Date.today)
      "#{FILE_STUB}_#{date.strftime("%Y_%m_%d")}.sql.gz"
    end
    
    # db backups have n steps:
    #   (0) on WEBSITE machine: scrub useless data
    #   (1) on WEBSITE machine: sql backup
    #   (2) on SmartFlix::Application::BACKEND machine: pull
    #   (3) on SmartFlix::Application::BACKEND machine: scrub and cache for devel use
    
    
    # step 0: Purge uneeded data from the database (ie never used sessions, etc)
    #
    #    prod:  ?? minutes
    #    devel:  0 minutes
    def self.db_purge(logger = Rails.Logger)
      # This may seem roundabout, but simpler ways ran into obstacles...
      to_delete = ActiveRecord::Base.connection.select_all("SELECT sessions.id FROM sessions LEFT JOIN origins ON sessions.id = origins.session_id
                                                            WHERE ISNULL(origins.session_id) AND (DATEDIFF(NOW(), sessions.updated_at) > 45)").map { |record| record['id'] }
      to_delete.each_slice(1000) do |to_delete_slice|
        ActiveRecord::Base.connection.delete("DELETE FROM sessions WHERE sessions.id IN (#{ to_delete_slice.join(',')})")
      end
      logger.info "Deleted #{to_delete.size} rows from the sessions table"
    end


    # step 1  
    #    prod:  ?? minutes
    #    devel:  2 minutes
    def self.db_dump(logger = Rails.logger) 
      db_dump_internal(["sessions"], FRONTEND_DB_DIR)
    end


    # step 2
    #    prod:  ?? minutes
    #    devel:  n/a
    def self.db_pull(logger = Rails.logger) 
      if DEVEL
        cmd = "cp #{FRONTEND_DB_DIR}#{db_filename} #{SmartFlix::Application::BACKEND_DB_DIR}"
        # result = `#{cmd}`
        puts "nothing to do"
      else
        src = FRONTEND_URL
        dst = BACKEND_DB_DIR
        
        cmd = "rsync -va -e 'ssh -i /home/smart/.ssh/nopasswd -p22 -l#{SSH_USER}' #{src} #{dst} 2>&1"
        logger.info "* about to execute #{cmd}"
        logger.info "* expected duration == ~85 minutes"
        result = `#{cmd}`
      end
    end

    # step 3
    #    prod:  ?? minutes
    #    devel:  2 minutes
    def self.db_scrub(logger = Rails.logger) 
      date = DEVEL ? Date.today : (Date.today - 1)
      infile  = "#{BACKEND_DB_DIR}/#{db_filename(date)}"
      outfile = "#{BACKEND_CLEAN_DIR}/#{SCRUBBED_NAME}"
      
      puts "infile = #{infile}"
      puts "outfile = #{outfile}"

      # There's prob an existing out there from the last run.
      # Detect if we're going to fail before we pollute this existing resource.
      #
      raise "input #{infile} does not exist - ERROR!" unless File.file?(infile)
      
      logger.info "Scrubbing #{infile} and writing to #{outfile} ..."
      
      logger.info `gzip -d -c #{ infile} | egrep -v 'INSERT INTO .(sessions|ab_test_visitors|ab_test_results|origins|url_tracks)' | egrep -v 'USE .#{DB_NAME}' | gzip -c > #{outfile}`
      
      logger.info "Done: file #{outfile} now exists! ********************"
    end

    # step 4:    rake db:import
    #    prod:   n/a
    #    devel:  10 minutes
    #  
    #    ** NOT a 'job_runner do <cmd>' ... something you type from the cmd line!



    # This job merely marks hopeless copies as DEATH_LOST_BY_CUST_UNPAID
    #
    # It does not do anything tricky like trying to charge expired
    # credit cards, etc.  We can always come back later and do that.
    #
    def self.mark_hopeless_copies(logger = Rails.logger) 
      Copy.candidates_for_lbcu.each { |copy|
        logger.info "* Marked copy #{copy.sticker_id} as unlikely to return"
        copy.mark_as_lost_by_cust_unpaid("marked by automated job JobRunner.mark_hopeless_copies on #{Date.today}")
      }
    end


    def self.credit_affiliates(logger = Rails.logger) 
      AffiliateEngine.logger = logger.method( :info )
      AffiliateEngine.credit_affiliates
    end


    # We cache the expected delays for each position in the queue for each DVD
    # (e.g. for "Lathe Basics":
    #     1st person in line waits 0 days, 
    #     2nd waits 10 days,
    #     3rd waits 12 days,
    #     etc.
    #
    # That's all stored in table ProductDelay.
    #
    # Freshen that table.
    #
    def self.update_product_delays(logger = Rails.logger) 

      logger.info "* Updating product delays"
      logger.info "  ... this will take a LONG time.  Maybe days."

      before = Time.now
      num = Video.count
      ii = 0

      condition_txt = "display = 1"
      if Rails.env == 'development'
        logger.info "   ... truncating to 20 products in development"
        condition_txt += "and product_id < 20"
      end

      logger.info "  ... #{Video.count(:conditions => condition_txt)} videos"

      Video.find(:all, :conditions => condition_txt).each do |product|
        ii += 1
        logger.info " ... #{ii} / #{ num } done - #{Time.now}"  if ii % 10 == 0
        product.update_product_delays
      end

    end


    # what products should we pimp on the front page ? 
    #
    def self.update_featured_products(logger = Rails.logger) 

      FeaturedProduct.destroy_all
      Product.get_featured(250).each { |product|
        FeaturedProduct.create(:product_id => product.id)
      }

    end


    # populate three tables:
    #    product_recommendations
    #    customer_product_recommendations
    #    customer_category_recommendations

    def self.update_product_recommendations(logger = Rails.logger) 
      db = LineItem.connection

      logger.info "* Running Reco Engine" 
      RecommendationEngine.logger = logger.method( :info )

      re = RecommendationEngine.new()

      re.toplevel_do_products_recommendations
      re.toplevel_do_customer_products
      re.toplevel_do_customer_cats

    end



    def self.website_rebuild_search(logger = Rails.logger) 
      logger.info "Rebuilding index #{Rails.env}"
      ret = Searcher.rebuild_indexes(logger)
      logger.info  ret
      if ret.match(/abort/) 
        logger.info "ERROR"
        raise "error" 
      else
        logger.info "Rebuild complete"
      end
    end

    #==========
    # Sweep fragment caches
    #==========
    def self.sweep_cache(logger = Rails.logger) 
      logger.info "Sweeping cache of type #{RAILS_CACHE.class}"

      case RAILS_CACHE
        when ActiveSupport::Cache::MemoryStore
          logger.info "  ... memory store (should just be for devel)"
          RAILS_CACHE.clear        
        when ActiveSupport::Cache::MemCacheStore
          logger.info "  ... memory cache store"
          RAILS_CACHE.clear
        else
          raise "unsupported cache scheme #{RAILS_CACHE.class}"  
          # cache_files = "#{Rails.root}/#{ActionController::Base.fragment_cache_store.cache_path}/*"
          # raise 'CHECK THE CACHE PATH!!!!!!!!!' if cache_files.match(/\.\./)
          # system "rm -rf #{cache_files}"
      end

      logger.info "Cache swept"
    end

    def self.charge_expired_ccs_as_lost(logger = Rails.logger) 
      raise "not working yet"
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.charge_expired_ccs_as_lost
    end

    def self.pending_list_failed(logger = Rails.logger) 
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.pending_list_failed    
    end

    def self.pending_list_open(logger = Rails.logger) 
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.pending_list_open
    end

    #----------
    # bill
    #----------

    def self.bill_pending(logger = Rails.logger) 
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.pending_charge
    end

    def self.bill_late_dvds_charge(logger = Rails.logger) 
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.charge_weekly
    end



    def self.late_dvds_warn(logger = Rails.logger) 
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.send_first_overdue_email
    end

    def self.out_of_stock_mail(logger = Rails.logger) 
      logger.info "Calculating out-of-stock list...\n\n"
      orders = Shipping.unshippable_oos_mention
      logger.info "Sending email to customers about #{orders.size } OOS shipments:"
      orders.each do |order|
        if order.customer.nil?
          logger.info " * ERROR on order #{order.id}"          
          next
        end
        logger.info " * Sending email to #{order.customer.email} re order #{order.id}"

        begin
          email_to = Rails.env == 'production' ? order.customer.email : TVR_DEVELOPER_EMAIL
          SfMailer.oos_email(email_to, order.customer, order.line_items_uncancelled.map(&:product))
        rescue => e
          logger.error " *** ERROR sending email! #{e.to_s}"
        end
        order.update_attributes(:unshippedMsgSentP => true)
      end
      logger.info "\n\nDone."
    end


    #==========
    # univ stuff
    #==========

    def self.bill_univ_students(logger = Rails.logger) 
      OverdueEngine.logger = logger.method( :info )
      OverdueEngine.bill_univ_students
    end


    # Purpose: figure out if we've got univs with too little stock to support them
    #
    # BUG:
    #   * if a univ customer has a potential non-univ shipment going out today, we'll
    #     assume that that is a univ item, and thus under-report need for purchasing.
    #
    #   * not integrated with purchasing tool
    #
    #   * doesn't give us any advance warning - only complains when we're actually screwing
    #       a customer.
    #
    # Idea:
    # * refactor / reuse the shipment calculation: add a few fictional
    #     subscribers to each univ (maybe 10% of the existing customer
    #     base?), and then run the shipment calculation, making sure
    #     that not even the fictional subscribers are screwed.  If
    #     we've got enough to serve them, then we've got enough to
    #     serve all of our current customers, with a bit of breathing
    #     room.

    def self.university_inventory_warnings(logger = Rails.logger) 
      logger.info "University shortfalls:"
      logger.info "      today // in a 1 week, when on-order-from-vendor arrives"
      logger.info "      ------  -----------------------------------------------"
      today_sum = 0
      next_week_sum = 0
      University.find(:all).each do |u|
        shortfall_today, shortfall_one_week = u.inventory_shortfall
        UnivInventoryInfo.create!(:university => u, :shortfall_today => shortfall_today, :shortfall_one_week => shortfall_one_week)

        next if shortfall_one_week <= 0

        today_sum += shortfall_today
        next_week_sum += shortfall_one_week
        logger.info "      * #{sprintf('%3i', shortfall_today)}   // #{sprintf('%3i', shortfall_one_week)} // #{u.name}"
      end
      logger.info "        ------  -----------------------------------------------"
      logger.info "total:    #{sprintf('%3i', today_sum)      }   // #{sprintf('%3i', next_week_sum)}"
    end

    def self.sysadmin_info(logger = Rails.logger) 
      results =  `df .`
      logger.info `df .`
      percent_full = results.split("\n")[1].gsub(/\s+/, " ").split(" ")[4].to_i
      raise "disk too full (#{percent_full}%)!" if percent_full > 90
    end

    #==========
    # Send email to customers about new shipments going out to them
    #==========
    def self.shipment_emails(logger = Rails.logger) 
      
      shipments = Shipment.find(:all, :conditions => 'dateOut > DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND email_sent = 0');
      
      logger.info "Sending email to customers about shipments (#{shipments.size} to send)"
      
      shipments.each do |shipment|
        
        if shipment.line_items.size == 0
          logger.warn " *** Shipment ID #{shipment.id} has no line items"
          shipment.update_attributes!(:email_sent => true)
          next
        end

        if shipment.customer.nil?
          logger.warn " *** no customer on shipment #{shipment.id}"          
          next
        end

        
        products = shipment.products.collect(&:name)
        
        # Find anything *not* being shipped to this customer ... but
        customer = shipment.line_items.first.order.customer
        unfulfilled_products = customer.unfulfilled_line_items.reject {|li| li.order.university}
        unfulfilled_products = unfulfilled_products.map { |li| li.product.name }
        
        # Send to customer if production, developer if devel
        email_to = Rails.env == 'production' ? customer.email : TVR_DEVELOPER_EMAIL
        
        logger.debug " * Sending email to #{email_to}"
        begin
          SfMailer.shipment_email(email_to, customer, shipment, products, unfulfilled_products)
        rescue => e
          logger.error " *** ERROR sending email! #{e.to_s}"
        end
        
        shipment.update_attributes!(:email_sent => true)
        
      end
      
    end
    
    def self.solicit_univ_reviews(logger = Rails.logger) 
      raise "not working yet"
      candidates = Order.university_orders.select { |o| o.shipments.size >= 2}
      candidates = candidates.select { |o| Rating.find_by_product_id_and_customer_id(o.university.univ_stub.id, o.customer_id).nil? }

      logger.info "Sending email to #{candidates.size} customers to review universities"

      unless Rails.env == 'production'
        candidates = candidates[30,5]
        logger.info " ... truncating to 5 in non-production mode"
      end

      candidates.each do |order|

        customer = order.customer

        next unless customer.send_announcement_email?

        univstub = order.university.univ_stub
        token = OnepageAuthToken.create_token(customer, 3, :controller => 'store', :action => 'review', :id => univstub.id)
        review_url = "http://smartflix.com/store/review/#{univstub.id}?token=#{token}"


        SfMailer.solicit_univ_reviews(customer, univstub, review_url)

        logger.info " * Sending email to #{customer.email} about #{univstub.name}"
        
      end

    end
    
    # On 24 Feb 2011 XYZ fubared the univ charging code and charged
    # ~600-700 customers w long cancelled univs.  Apologize to them.
    #
    def self.univ_mistaken_charge_mail(logger = Rails.logger) 
      logger.info " * Calculating..."
      orders = Payment.find(:all, :conditions => "payment_id >= 572569").select {|p| p.successful}.map(&:order).select { |o| o.payments[1] && o.payments[1].created_at < (Date.today << 2) } 
      logger.info "     #{orders.size} to send"

      if Rails.env == 'development' 
        orders = orders[0,5] 
        logger.info "     truncated to #{orders.size} in devel"
      end

      logger.info "Sending email to customers about mistaken charges"
      orders.each do |o|
        logger.info " * Sending email to #{o.customer.email} re order #{o.id}"
        begin
          SfMailer.univ_mistaken_charge(o.customer, o)
        rescue => e
          logger.error " *** ERROR sending email! #{e.to_s}"
        end
      end
      logger.info "\n\nDone."
    end

    
    #==========
    # Send email to customers about videos they return
    #==========
    def self.return_emails(logger = Rails.logger) 
      
      returns = LineItem.find(:all, :conditions => 'dateBack > DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND return_email_sent = 0')
      
      # If we ever want to bin customers by email address
      # returns_by_email = returns.group_by { |li| li.order.customer.email }
      
      logger.info "Sending email to customers about returns (#{returns.size} to send)"
      
      returns.each do |line_item|
        
        product = line_item.product.name
        email_addr = line_item.order.customer.email
        
        # Send to customer if production, developer if devel
        email_to = Rails.env == 'production' ? email_addr : TVR_DEVELOPER_EMAIL
        
        # Set up review URL
        customer = line_item.order.customer
        base_product = line_item.product.base_product
        token = OnepageAuthToken.create_token(customer, 3, :controller => 'store', :action => 'review', :id => base_product.id)
        review_url = "http://smartflix.com/store/review/#{base_product.id}?token=#{token}"
        
        logger.debug " * Sending email to #{email_to} about #{product}"
        begin
          SfMailer.return_email(email_to, product, review_url)
        rescue => e
          logger.error " *** ERROR sending email! #{e.to_s}"
        end
        
        line_item.update_attributes!(:return_email_sent => true)
        
      end
      
    end
    
    #==========
    # Check for carts which have been abandoned and email the customers regarding them
    #==========
    def self.abandoned_basket_emails(logger = Rails.logger) 
      AbandonedBasketEngine.logger = logger.method( :info )
      AbandonedBasketEngine.abandoned_basket_emails
    end

    # effectively duplicated in app/controllers/copies_controller.rb, consistency()
    def self.db_consistency_check(logger = Rails.logger) 
      logger.info "\n\nsee https://smartflix.com/admin/copies/consistency\n\n"

      Copy.ERRORCHECK_in_and_out_not_one.each do |copy|
        logger.info "* #{copy.sticker_id} in + out != 1, out #{copy.times_out}, inStock #{copy.inStock }, death #{copy.death_type.andand.name}"
      end
      Copy.ERRORCHECK_lost_and_actually_here.each do |copy|
        logger.info "* #{copy.sticker_id} lost yet believed to be in stock, #{copy.times_out}, inStock #{copy.inStock }, death #{copy.death_type.name}"
      end

      Order.ERRORCHECK_payments_exist.each do |order|
        logger.info "* #{order.order_id} has no payments"
      end

      Order.ERRORCHECK_order_date.each do |order|
        logger.info "* order #{order.order_id} invalid"
      end

      LineItem.ERRORCHECK_find_orderless.each do |li|
        logger.info "* line_item #{li.line_item_id} points to nonexistant order #{li.order_id}"
      end

      Product.ERRORCHECK_no_categories.each do |product|
        logger.info "* product #{product.product_id} has no categories"
      end

      Product.ERRORCHECK_no_vendor.each do |product|
        logger.info "* product #{product.product_id} has no vendor"
      end

      Payment.ERRORCHECK_no_overprocessing.each do |payment|
        logger.info "* payment #{payment.payment_id} has #{payment.retry_attempts} retry attempts"
      end

      logger.info "\n\n"
    end

    
    #==========
    # Send scheduled marketing emails to customers
    #==========

    # get new customers
    #
    def self.marketing_email_univ_new(logger = Rails.logger) 
      ScheduledEmailer.logger = logger.method( :info )
      ScheduledEmailer.recruit_new_univ_customers
    end

    # recover old customers
    #
    def self.marketing_email_univ_old(logger = Rails.logger) 
      ScheduledEmailer.logger = logger.method( :info )
      ScheduledEmailer.recruit_old_univ_customers
    end

    def self.marketing_email_browsed(logger = Rails.logger) 
      ScheduledEmailer.logger = logger.method( :info )
      ScheduledEmailer.email_about_browsed_items
    end


    
    #==========
    # Pay affiliate customers who are owed payment
    #==========
    def self.pay_affiliates(logger = Rails.logger) 
      AffiliateTransaction.find(:all).group_by(&:affiliate_customer).each do |affiliate, transactions|
        amount_owed = transactions.inject(0.0) { |sum, t| sum + t.amount }
        pay_now = amount_owed >= 50.0
        first_payment = transactions.detect { |t| t.transaction_type == 'P' }.nil?
        if pay_now
          address = affiliate.shipping_address
          logger.info "Pay $#{"%0.2f" % amount_owed} to"
          logger.info ""
          logger.info "  #{address.first_name} #{address.last_name}"
          logger.info "  #{address.address_1}"
          logger.info "  #{address.address_2}" if address.address_2.size > 0
          logger.info "  #{address.city}, #{address.state} #{address.postcode}"
          logger.info ""
          logger.info "  FIRST PAYMENT, NEW PAYROLL SETUP REQUIRED" if first_payment
          logger.info "" if first_payment
          AffiliateTransaction.create(:transaction_type => 'P', 
                                      :affiliate_customer => affiliate,
                                      :amount => (amount_owed * -1.0), 
                                      :date => Date.today)
        end
      end
      return
    end
    
    #==========
    # calculate purchasing task
    #==========
    def self.calculate_purchasing(logger = Rails.logger) 

      logger.info "==== updating copy delays"
      before = Time.now
      ii = 0
      videos = Video.find(:all)

      videos.each do |product|
        # run garbage collector every 50 products
        #
        ii += 1
        if (0 == (ii % 50)) 
          GC.start 
        end
        
        before = Time.now
        copies_needed, pain = product.update_tobuy()

        logger.info "#{product.id} - #{ (copies_needed > 0) ? "****" : "    "} #{product.name} : need #{copies_needed} // #{Time.now - before} seconds"
      end

      logger.info ""
      logger.info "==== adding in univ shortfalls"
  
      univs = University.find(:all)

      University.logger = logger
      total = 0
      univs.each do |univ|
        total += univ.update_tobuy.to_i
      end
      logger.info "...added #{total} for univs"
    end



    def self.vidcap_needed(logger = Rails.logger) 
      logger.info "about to do an 'svn up' to get new vidcaps in dir #{SmartFlix::Application::BACKEND_VIDCAP_LOCATION}";

      # do the SVN up
      #
      raise "vidcap dir does not exist #{SmartFlix::Application::BACKEND_VIDCAP_LOCATION}"      unless FileTest.exists?(SmartFlix::Application::BACKEND_VIDCAP_LOCATION)
      Dir.chdir(SmartFlix::Application::BACKEND_VIDCAP_LOCATION)
      ENV['SVN_SSH'] = "ssh -i /home/autorun/.ssh/nopasswd_for_svn_nitrogen_to_nitrogen"
      `svn up`

      logger.info "about to do do calc."
      limit = nil
      products = Product.find(:all, :limit => limit, :include => [ :product_set_membership, :copies ] ).select(&:first_in_set_or_standalone).reject { |p| 
        FileTest.exists?("videocap_#{p.product_id}.jpg")  
      }.select(&:display).select { |p| p.copy_available?}

      logger.info "Need vidcaps for:"
      if products.any?
        products.each { |p| logger.info  " * #{p.name} (#{p.id})"       }
      else
        logger.info " ... nothing."
      end

    end

    # WHERE
    #   This gets run on the backend, where we've got access to version control
    #   We have a vidcap directory that persists from cap deploy to cap deploy.
    #   This vidcap directory both
    #     1) gets svn updated
    #     2) has new files generated in it, by the following process
    #        NOTE: these new files do ** NOT ** get checked in 
    #        (there's no reason why they couldn't; it's just not set up that way)
    #
    # WHAT / HOW
    #   This process
    #      1) does an svn up
    #      2) generates new sized images
    #      3) rsyncs to the frontend customer-facing website
    def self.vidcap_push(logger = Rails.logger) 
      
      logger.info "Pushing vidcaps"

      # do the SVN up
      #
      raise "vidcap dir does not exist"      unless FileTest.exists?(SmartFlix::Application::BACKEND_VIDCAP_LOCATION)
      Dir.chdir(SmartFlix::Application::BACKEND_VIDCAP_LOCATION)
      ENV['SVN_SSH'] = "ssh -i /home/autorun/.ssh/nopasswd_for_svn_nitrogen_to_nitrogen"
      `svn up`
     
      # Create any new vidcaps needed
      Dir['videocap_*.jpg'].each do |file|
        
        match = file.match(/^videocap_([0-9]+)\.jpg$/i)
        next if !match
        vid_num = match[1]
        
        # New, tiny (75x75 px) images for "Rent this together with that" feature
        tiny = "railscart/tvidcap_#{vid_num}.jpg"
        if (FileTest.exists?(tiny) && File.mtime(file) > File.mtime(tiny))
          logger.info " * Deleting obsolete version of #{tiny}"
          File.unlink(tiny)
        end
        if (!FileTest.exists?(tiny))
          logger.info " * Creating #{tiny}"
          system "composite -quality 75 -compose over -geometry 75x75 tiny_window.gif #{file} #{tiny}"
        end
        
        small = "railscart/svidcap_#{vid_num}.jpg"
        if (FileTest.exists?(small) && File.mtime(file) > File.mtime(small))
          logger.info " * Deleting obsolete version of #{small}"
          File.unlink(small)
        end
        if (!FileTest.exists?(small))
          logger.info " * Creating #{small}"
          system "composite -quality 75 -compose over -geometry 109x109 small_window.gif #{file} #{small}"
        end
        
        small_new = "railscart/svidcap_#{vid_num}_new.jpg"
        if (FileTest.exists?(small_new) && File.mtime(file) > File.mtime(small_new))
          logger.info " * Deleting obsolete version of #{small_new}"
          File.unlink(small_new)
        end
        if (!FileTest.exists?(small_new))
          logger.info " * Creating #{small_new}"
          system "composite -quality 90 -compose over -geometry 109x109 small_window_new.png #{file} #{small_new}"
        end
        
        large = "railscart/lvidcap_#{vid_num}.jpg"
        if (FileTest.exists?(large) && File.mtime(file) > File.mtime(large))
          logger.info " * Deleting obsolete version of #{large}"
          File.unlink(large)
        end
        if (!FileTest.exists?(large))
          logger.info " * Creating #{large}"
          system "composite -quality 85 -compose dst-over #{file} big_window.gif #{large}"
        end
        
      end
      
      # Do the rsync to the server, results to verbose output (production only)
      if (Rails.env == 'production')
        Dir.chdir('railscart')
        ssh = "'ssh -i #{ENV['HOME']}/.ssh/nopasswd -p22 -l#{SSH_USER}'"
        # Need to split them up because count is getting too large
        logger.info `rsync -vcaz -e #{ssh} t*[0-9].jpg smartflix.com:/home/smart/rails/railscart/vidcaps/`
        logger.info `rsync -vcaz -e #{ssh} s*[0-9].jpg smartflix.com:/home/smart/rails/railscart/vidcaps/`
        logger.info `rsync -vcaz -e #{ssh} l*[0-9].jpg smartflix.com:/home/smart/rails/railscart/vidcaps/`
        logger.info `rsync -vcaz -e #{ssh} s*new.jpg smartflix.com:/home/smart/rails/railscart/vidcaps/`
      else
        logger.info "***** no rsync in #{Rails.env} mode !!!"
      end
      
      
    end

    
    
    def self.wishlist_emailer(logger = Rails.logger) 
      TVR::WishlistDiscountEmailer.run
    end

    def self.recalc_shipping(logger = Rails.logger) 
      Shipping.logger = logger.method( :info )
      Shipping.toplevel_recalc
    end

    def self.print_snailmail(logger = Rails.logger) 
      customers_printed = Customer.print_all_snailmails(logger)
      logger.info("printed #{customers_printed.size} letters")
    end
    
    def self.ebay_post(logger = Rails.logger) 
      SmartflixEbay.logger = logger.method( :info )
      SmartflixEbay.post_all
    end
    
    def self.ebay_finalize(logger = Rails.logger) 
      eb = SmartflixEbay.new
      eb.logger = logger.method( :info )
      eb.ebay_finalize
    end
    
    def self.google_products(logger = Rails.logger) 
      gp = GoogleProducts.new(logger.method( :info ))
      
      file = gp.create_products_xml
      gp.ftp(file)
      
      file = gp.create_reviews_xml
      gp.ftp(file)
    end
    
    def self.smartflix_adwords(logger = Rails.logger) 
      SmartflixAdwords.logger = logger.method( :info )
      SmartflixAdwords.new.update_to_google
    end

    def self.test_univstub_download_speed(logger = Rails.logger) 
      require 'mechanize'
      agent = WWW::Mechanize.new
      
      UnivStub.find(:all).each { |stub| 
        before = Time.now 
        agent.get("http://smartflix.com/store/video/#{stub.id}")
        logger.info "#{stub.name} ... #{Time.now - before}"
      }
    end
    
    #==========
    # reminder emails to staff
    #==========

    def self.remind_newsletter(logger = Rails.logger) 

      before = Date.parse("1900-01-01")
      newsletter = Newsletter.last_with_recipients
      before = newsletter.recipients.last.updated_at.to_date if newsletter
      
      ideal = 30
      delta = (Date.today - before).to_i
      subj = "[ SmartFlix ] newsletter reminder ( #{delta} days )"

      if delta > ideal
        body = "It has been #{delta} days since a newsletter (should go every 30)."
        subj << " *** DO IT NOW ***"
      elsif delta > (ideal - 10)
        body = "It has been #{delta} days since a newsletter. Please do it soon (should go every 30)"
        subj << " *** DO IT SOON ***"
      else

      end

      recipient = (Rails.env == 'production') ? "susanc@smartflix.com,xyz@smartflix.com" : EMAIL_TO_DEVELOPER

      SfMailer.simple_message(recipient, SmartFlix::Application::EMAIL_FROM_AUTO, subj, body)
      logger.info body
    end


    def self.remind_inventory_status(logger = Rails.logger) 
      subj = "SmartFlix inventory freshness"
      
      fresh = Inventory.freshness_percent
      body = "SmartFlix DVD inventory freshness at #{sprintf("%2.2f%%", fresh)}\n\n"
      body << "URGENT: Do inventory now!!!" if fresh < 50.0
      
      logger.info  Person.send_email_polishing(subj, body)
    end
    
    def self.remind_customers_with_tons(logger = Rails.logger) 
      subj = "Customers with tons of DVDs"
      body = ""
      body << "The following customers have A LOT of dvds out.\n\n"
      
      Customer.customers_with_tons_of_dvds.each do |cust, lis|
        body << "* #{sprintf("%6i", cust.id)} // #{sprintf("%40s", cust.email)} :   #{sprintf("%4i", lis.size)}\n"
      end
      
      logger.info  Person.send_email_custsupport_sf(subj, body)
    end
    


    def self.remind_bbb_status(logger = Rails.logger) 
      subj = "Better Business Burea status"
      
      body = "Check out our status at Better Business Bureau\n"
      body << "\n"
      body << "...and make sure that we've got an A rating, and no open customer complaints\n"
      body << "\n"
      body << "   http://www.bbb.org/boston/business-reviews/video-tapes-and-discs-sales-and-rentals/smartflix-in-arlington-ma-37159/\n"
      body << "\n"
      body << "Login at   http://our.bbb.org/boston/Public/Login/BusinessLogin.aspx\n"
      body << "\n"
      body << "   ID:    37159\n"
      body << "   email: xyz_bbb_org@smartflix.com\n"
      body << "   pwd:   02476\n"
      logger.info  Person.send_email_custsupport_sf(subj, body)
    end
    

    def self.remind_pay_per_rent_invoice(logger = Rails.logger) 
      subj = "pay per rent invoice"
      
      if  Date.today.is_first_week_of_quarter?
        quart_beg = Date.today.plus_quarter(-1).beginning_of_quarter
        quart_end = Date.today.plus_quarter(-1).end_of_quarter
        
        body = "The following vendors get a payment for renting their DVDs between #{quart_beg.to_s} and #{quart_end.to_s}.\n\n\n"
        lis = Copy.find_all_by_payPerRentP(1).map { |copy| copy.line_items}.flatten
        lis = lis.select { |li| li.live == true && li.date >= quart_beg && li.date <= quart_end }
        
        lis.group_by { |li| li.product.vendor.name }.each_pair do |vendor, vendor_lis|
          body << "#{vendor} - $ #{vendor_lis.size }\n"
          body << "-------\n"
          
          vendor_lis.group_by { |li| li.product.name}.each_pair do |name, product_lis|
            body << "#{product_lis.size} of #{name}\n"
          end
          body << "\n\n"
        end
        
        logger.info  Person.send_email_finance(subj, body)
      else
        logger.info "Not time to send reminder (just during first week of quarter)"
      end
    end
    
    def self.remind_polishing(logger = Rails.logger) 
      subj = "polishing reminder"
      
      body = "You can see this at http://smartflix.com/admin/purchasing/polishable\n\n"
      high = Purchasing.polishable_high
      body <<  "Polish ASAP - a customer is waiting (#{ high.size} items) :\n"
      high.sort.each {  |sticker_id|        body << "  *  #{Copy.id_to_sticker(sticker_id)}\n" }

      med = Purchasing.polishable_med
      body << "\n\nPolish ASAP - only 1 good copy (" << med.size.to_s << " items) :\n"
      med.sort.each {  |sticker_id|        body << "  *  #{Copy.id_to_sticker(sticker_id)}\n" }

      low = Purchasing.polishable_low
      body << "\n\nPolish later - noone waiting (yet) (" << low.size.to_s << " items) :\n"
      low.sort.each {  |sticker_id|        body << "  *  #{Copy.id_to_sticker(sticker_id)}\n" }
      
      logger.info Person.send_email_polishing(subj, body)
    end
    
    def self.remind_custsup_happy(logger = Rails.logger) 
      subj = "customer happiness reminder"
      
      body =  "\nThe following customers expressed unhappiness via the survey.\n"
      body << "Please use tvr-master to address these issues.\n\n"
      Survey.find_failing_and_unaddressed.each {  |failing_survey| body << "  *  #{failing_survey.customer.email}\n" }
      
      logger.info  Person.send_email_custsupport_sf(subj, body)
    end
    
    def self.remind_custsup_ebay(logger = Rails.logger) 
      subj = "check on ebay reminder"
      
      body =  "\n\nPlease log on to ebay and make sure that all customer support issues are addressed.\n"
      body << "We have been thrown off of ebay once before because we did not promptly address concerns, and this had a major financial impact on the firm.\n"
      body << "Thanks!"
      
      logger.info  Person.send_email_custsupport_sf(subj, body)
    end
    
    def self.remind_custsup_snailmail(logger = Rails.logger) 
      subj = "send late-dvd snailmail reminder "
      
      body = "\nPlease\n"
      body << "\n"
      body << "1) verify paper in printer\n"
      body << "2) at command line: cd bus/tvr/src/rails/tvr-master\n"
      body << "3) at command line: script/console production\n"
      body << "4) at command line: Customer.print_all_snailmails\n"
      body << "5) at command line: exit\n"
      body << "6) mail\n"
      body << "\n"
      body << "Thanks!\n"
      
      logger.info  Person.send_email_custsupport_sf(subj, body)
    end
    
    def self.remind_finance(logger = Rails.logger) 
      subj = "reminder finance"
      
      body = ""
      body << "\nThis is an automated reminder of tasks.\n"
      body << "You will receive it once per month.\n"
      body << "More details at http://helium/mediawiki/index.php/Job_Description:_Bookkeeper#monthly\n\n\n"
      body << "\nWeekly:\n"
      body << "   * top off Purchasing account\n"
      body << "   * cut checks to affiliates (use tvr-master)\n"
      if Date.today.is_first_week_of_month?
        body << "\nMonthly:\n"
        body << "   ...no monthly tasks\n"
      end
      if Date.today.is_first_week_of_quarter?
        body << "\nQuarterly:\n"
        body << " * pay MA sales tax for SF, HI\n"
        body << " * cut checks to cobrands (use tvr-master)\n"
      end
      if Date.today.is_first_week_of_year?
        body << "\nAnnually:\n"
        body << " * pay State, Federal income taxes\n"
        body << " * call timepays, update all IRA prefixes from '2009' to '2010' \n"
        body << "   details: http://helium/mediawiki/index.php/Retirement_planning_/_IRA_/_401(k)\n"
      end
      
      logger.info  Person.send_email_finance(subj, body)
    end
    
    def self.remind_marketing(logger = Rails.logger) 
      subj = "marketing duties reminder"
      
      body = "\nThis is an automated reminder of tasks."
      body << "You will receive it once per month.\n"
      body << "See also other tasks at http://helium/mediawiki/index.php/Job_Description:_Marketing_Intern\n\n"
      body << "Monthly:\n"
      body << " * update some of the unknown campaigns - http://helium/tvr-master/campaigns/index_of_unknown\n"
      
      logger.info  Person.send_email_marketing_sf_intern(subj, body)
    end
    
    def self.remind_purchasing(logger = Rails.logger) 
      subj = "need prices on overdue items reminder "

      products = Product.no_prices_on_overdue.sort_by { |tt| tt.vendor.name}
      body = "\nThe following #{products.size} products need prices.\n\n"
      products.each do  |product| 
        body << "  *  #{product.vendor.name} - #{product.id} - #{product.name}\n" 
      end

      logger.info  Person.send_email_purchasing(subj, body)
    end

    def self.backup_pruner(logger = Rails.logger) 
      BackupPruner.logger = logger.method( :info )
      BackupPruner.prune("/home/autorun/external-db-backups")
    end

    def self.smartflix_pruner(logger = Rails.logger) 
      BackupPruner.logger = logger.method( :info )
      BackupPruner.prune("/backup/db")
    end

    
    def self.remind_delayed_vendors(logger = Rails.logger) 
      subj = "delayed vendor orders reminder "
      
      body = "\nThe following vendor orders have not arrived.\n\n"
      InventoryOrdered.delayed_vendor_orders.each do |io| 
        body << " * order not arrived: #{io.product.id} (#{io.product.name}), #{io.recent} , #{io.quant_dvd} copies from #{io.product.vendor.name}\n" if ! io.product.nil?
      end
      
      logger.info  Person.send_email_purchasing(subj, body)
    end
    
    
    # tell the person in charge of writing checks to the USPS how much they have to write
    def self.remind_postage(logger = Rails.logger) 
      subj = "cust postage checks to USPS reminder"
      
      shipments = Shipment.find(:all, :conditions => "dateOut >= '#{(Date.today - 7).to_s}'")
      busrep_cost = shipments.inject(0){|sum, ship| sum + ship.bus_reply_cost }
      permit_cost = shipments.inject(0){|sum, ship| sum + ship.permit_imprint_cost }
      body = ""
      body << "Bus Reply\n"
      body << "       7 days:  $#{sprintf("%0.2f",busrep_cost)}\n"
      body << "       payable: Postmaster Boston\n"
      body << "       memo:    bus rep 615-001\n"
      body << "       to:      Jimmy\n"
      body << "                Arlington PO\n"
      body << "                7 Court St\n"
      body << "                Arlington MA 02476\n"
      body << "                \n"
      body << "Permit Imprint\n"
      body << "       7 days:  $#{sprintf("%0.2f",permit_cost)}\n"
      body << "       payable: Postmaster Boston\n"
      body << "       memo:    PI-789\n"
      body << "       to:      Permit Fee Window\n"
      body << "                25 Dorchester Ave\n"
      body << "                Boston MA 02205\n"
      
      logger.info  Person.send_email_finance(subj, body)
    end

    # tell the person in charge of writing checks to transfer money from HI to SF
    def self.remind_hi_transfer_labor(logger = Rails.logger) 
      Date.force_today(Date.today - 1)

      subj = "transfer from HI to SF for labor"

      dollars = Person.live.sum {|person| person.hi_dollars(Date.today - 6, Date.today) }
      HiToSfTransfer.create!(:dollars => dollars, :memo => "labor")

      body = ""
      body << "HI to SF Transfer\n"
      body << "       labor: #{dollars}\n"

      if Date.today.is_first_week_of_month?
        dollars = 1000
        body << "       rent: #{dollars}"
        HiToSfTransfer.create!(:dollars => dollars, :memo => "rent")
      end
      
      logger.info  Person.send_email_finance(subj, body)
    end
    
    # tell the person in charge of writing checks to the USPS how much they have to write
    def self.remind_depreciation(logger = Rails.logger) 
      subj = "depreciation reminder"
      
      body = "\nSmartFlix DVD depreciation report\n\n"
      body << Depreciation.report(Depreciation.calculate[:depreciation])
      
      logger.info  Person.send_email_finance(subj, body)
    end    
    
    def self.remind_recycling(logger = Rails.logger) 
      if (((Date.today - Date.strptime("2007-01-01")) % 14).to_i == 7 )
        subj = "recycling goes out today"
        body = "Recycling goes out today by 5pm.  Thanks!"
        
        logger.info  Person.send_email_garbage(subj, body)
      end
    end

    def self.remind_clean_office(logger = Rails.logger) 
      subj = "Time to clean the office"
      body = "
Everyone:
  * empty your own garbage can
  * throw away all food containers and beverage bottles on your desk
  * pick up all cardboard scraps / dog toys / paperclips / shipping
       detritus from your area 

XYZ:
  * clean up kitchen area: empty garbage, clean up mugs, throw out
  food in fridge, etc.

Suz:
  * all cardboard boxes in your area are either broken flat and
      recycled, or taken out to your car
  * tidy up DVD polishing station, spray and wipe the desk there clean 

Andy: 
  * tidy the lunch room: EVERYTHING is removed and thrown away (not a
    single fork, napkin, or color book is left)

Julio: 
  * vacuum all common areas
"
      
      logger.info  Person.send_email_all(subj, body)
    end

    #----------
    # delayed jobs
    #----------
    def self.run_delayed_jobs(logger = Rails.logger) 
      dw  = Delayed::Worker.new(:quiet => false)
      ret = dw.work_off(1000)


      logger.info "success      = #{ret[0]}"
      logger.info "failure count = #{ret[1]}"

      attempts_0 = Delayed::Backend::ActiveRecord::Job.find(:all, :conditions => "attempts = 0").count
    # attempts_1 = Delayed::Backend::ActiveRecord::Job.find(:all, :conditions => "attempts >= 1 and attempts <= 2").count
      attempts_3 = Delayed::Backend::ActiveRecord::Job.find(:all, :conditions => "attempts >= 3").count
      logger.info "0 attempt jobs  (new)     remaining: #{sprintf("%7s", attempts_0.commify)}"
      logger.info "3+ attempt jobs (problem) remaining: #{sprintf("%7s", attempts_3.commify)}"

    end


  end
end

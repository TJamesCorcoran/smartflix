# Note that info on rental prices, late prices, and replacement prices
# is all stored/computed inside the product object.

class OverdueEngine
  @@logger = method(:puts)   
  cattr_accessor :logger


  @@results = {}
  @@results[:charge_fail] = []
  @@results[:missing_price] = []
  @@results[:success] = []

  def self.total_foo_price(copies, funcname)
    return nil if copies.detect{ |copy| copy.andand.product.send(funcname).nil? }
    copies.inject(0.0){ |sum, copy| sum + copy.product.send(funcname) }
  end

  def self.total_replacement_price(copies) total_foo_price(copies, :replacement_price)  end
  def self.total_late_price(copies) total_foo_price(copies, :late_price)  end

  #----------------------------------------
  # mid-level entry points: do thing for one person
  #----------------------------------------

  def self.late_dvd_onecust(customer, late_lis)
    price = total_late_price(late_lis)
    if price.nil? then @@results[:missing_price] << { :customer => customer, :late_lis => late_lis, :price => 0 } ; return  end

    order =  success = details = nil
    Order.transaction do    

      order = Order.note_late_charge(customer, late_lis)
      success, details = ChargeEngine.charge_customer(customer, price, order.id, "weekly charge")

      if  !success then
        @@results[:charge_fail] << { :customer => customer, :late_lis => late_lis, :price => price, :details => details } ; 
        raise ActiveRecord::Rollback
        # order.destroy_self_and_children(:line_items)
        # order.line_items.destroy_all
        # order.destroy

      end
    end
    return unless success
      
    SfMailer.weekly_charge(:customer => customer, 
                                 :copies => late_lis.map(&:copy),
                                 :weekly_rate => Product::LATE_WEEKLY_BASE, 
                                 :price => price,
                                 :last_four => details, 
                                 :in_last_chargeable_month => customer.in_last_chargeable_month? )
    
    details << " **** WARNED CC EXPIR" if customer.in_last_chargeable_month?
    @@results[:success] << { :customer => customer, :late_lis => late_lis, :price => price, :details => details } 
    order
  end
  
  def self.lost_dvd_onecust(customer, lost_lis, options ) 

    allowed = [:because_cc_expiring, :with_guessed_expiration ]

    raise "illegal options" if (options.keys - allowed).any?

    price = total_replacement_price(lost_lis)

    if price.nil? then @@results[:missing_price] << { :customer => customer, :late_lis => late_lis, :price => 0 } ; return  end

    success = false
    details = nil

    Order.transaction do
      order = Order.note_lost_charge(customer, lost_lis)

      success, details = ChargeEngine.charge_customer(customer, 
                                                      price, 
                                                      order.id, 
                                                      "copy lost charge", 
                                                      options[:with_guessed_expiration])    
      if ! success
        # raise ActiveRecord::Rollback 
        order.destroy_self_and_children(:line_items)
      end

    end

    if  !success
      @@results[:charge_fail] << { :customer => customer, :late_lis => lost_lis, :price => price, :details => details }
      return
    end      



    lost_lis.each do |li|
      li.copy.mark_as_lost_by_cust_paid("charged via overdue engine", li) if success
    end
    
    # XYZFIX P2: we don't create a payment object anywhere here.
    #     It's a bit tricky to do so, as the payment needs to pt to
    #     both the order (created one line up) and the credit card
    #     (which we only know about down in the charge engine).  The
    #     solution is probably to create the payment object down in
    #     the charge engine, pass a reference to it up to here, and
    #     then splice in the the ptr to the order

    copies = lost_lis.map(&:copy)

    SfMailer.lost_charge(:customer => customer, 
                               :copies => copies, 
                               :last_four => details,
                               :sum_price => price,
                               :because_cc_expiring => options[:because_cc_expiring])
    
    details << " **** CHARGED FOR LOST"
    @@results[:success] << { :customer => customer, :late_lis => lost_lis, :price => price, :details => details }     
  end
  
  def self.lost_dvd(options)
    @@logger.call "Overdue emails sent"
    @@logger.call "-------------------"

    customer_to_copies = Copy.unreturned_and_billable_for_overdue().copies.group_by { |copy| copy.last_line_item.order.customer }
    customers.each do |customer|
      next if customer.nil?  # weirdness
      lost_dvd_onecust(customer, late_lis, true)
    end
  end

  #----------------------------------------
  # utility functions
  #----------------------------------------

  def self.truncate_input_for_development_mode(grped_by_cust)
    if Rails.env == "development"
      subset = 20
      grped_by_cust = grped_by_cust[0,subset] 
      @@logger.call "****************************************"
      @@logger.call "*   charging just #{subset} items"
      @@logger.call "****************************************"
    end
    grped_by_cust
  end

  def self.print_summary( product)
    
    # print a summary of what we accomplished
    @@logger.call product
    @@logger.call "-------------------"
    @@results.keys.each do |status|
      @@logger.call sprintf("%-15s - %3i custs    $%6.2f", 
                          status.to_s,       
                          @@results[status].size, 
                          @@results[status].inject(0.0){ |sum, item|  sum + item[:price]} )
    end
    charged_dollars = @@results[:success].inject(0.0){ |sum, item|  sum + item[:price]}
    profit_dollars = charged_dollars - ChargeEngine.estimated_processing_fees_total
    profit_margin = profit_dollars / charged_dollars

    @@logger.call "\n\n"
    
    @@logger.call "Merchant Account stats"
    @@logger.call "--------------------"
    @@logger.call "charge attempts: #{ChargeEngine.stats[:charge_attempts]}"
    @@logger.call "charge success:  #{ChargeEngine.stats[:charge_success]}"
    @@logger.call "charge failures: #{ChargeEngine.stats[:charge_failures]}"
    @@logger.call "\n"
    @@logger.call "useful fees:     #{ChargeEngine.estimated_processing_fees_from_success}"
    @@logger.call "wasted fees:     #{ChargeEngine.estimated_processing_fees_from_failed}"
    @@logger.call "total fees:      #{ChargeEngine.estimated_processing_fees_total}"
    @@logger.call "\n"
    @@logger.call "profit:          #{sprintf('$%6.2f', profit_dollars)}"
    @@logger.call "profit margin:   #{sprintf('%%%0.2f', profit_margin)}"
    @@logger.call "\n\n"

    
    # print details
    @@results.keys.each do |status|
      @@logger.call status.to_s
      @@logger.call "--------------------"
      @@results[status].each do |item|
        @@logger.call sprintf("* %-30s  $%6.2f  %s", 
                            item[:customer].email, 
                            item[:price], 
                            item[:details])
      end
      @@logger.call "\n\n"
    end
  end
  #----------------------------------------
  # top-level entry points: do things for a lot of people
  #----------------------------------------
  
  def self.send_first_overdue_email
    @@logger.call "Overdue emails sent"
    @@logger.call "-------------------"

    lis_grouped_by_cust = LineItem.late_items_warnable.group_by(&:customer)
    
    @@logger.call "total customers: #{lis_grouped_by_cust.keys.size}"
    @@logger.call "total copies:    #{lis_grouped_by_cust.values.flatten.size}"
    @@logger.call "\n\n"

    unless Rails.env == 'production'
      count = 50
      lis_grouped_by_cust = lis_grouped_by_cust[200,count]
      @@logger.call " ... truncating to #{count} in non-production mode"
    end

    
    lis_grouped_by_cust.each do |customer, late_lis|
      SfMailer.first_overdue_email(:customer => customer, :copies => late_lis.map(&:copy), :weekly_rate => Product::LATE_WEEKLY_BASE )
      late_lis.each { |li| LineItem.find(li.id).update_attributes(:lateMsg1Sent => Date.today) }
      @@logger.call   "   *  #{customer.email}"
    end
  end


  def self.charge_expired_ccs_as_lost
    @@results = Hash.new { |hash, key| hash[key] = Array.new }

    # Get all the items we'd like to charge as late
    #
    # Three cases:
    #   * never tried before (newly late)
    #   * tried before, failed, zero of cards that we tried failed  b/c expired
    #   * tried before, failed, 1 or more cards that we tried failed b/c expired
    #
    # We care ONLY about the final case.

    grped_by_cust = LineItem.late_items_chargeable.group_by(&:customer)

    custs_with_expired_ccs = grped_by_cust.keys.select { |cust| 

      next if cust.nil?  # weirdness - there are a few old LIs that have no orders

      cust.credit_cards.map(&:expired_message?)
    }

    grped_by_cust = grped_by_cust.hash_select { |cust, lilist| custs_with_expired_ccs.include?(cust) }

    grped_by_cust = truncate_input_for_development_mode(grped_by_cust)

    grped_by_cust.each do |customer, late_lis|
      lost_dvd_onecust(customer, 
                       late_lis, 
                       :because_cc_expiring => false, 
                       :with_guessed_expiration => true)
    end



    print_summary("Expired CC Extrapolation attempts")
  end
  
  def self.charge_weekly
    @@results = Hash.new { |hash, key| hash[key] = Array.new }

    before = Time.now
    grped_by_cust = LineItem.late_items_chargeable.group_by(&:customer)
    @@logger.call "grped_by_cust = #{grped_by_cust.keys.size} customers // #{Time.now - before}"
    grped_by_cust = truncate_input_for_development_mode(grped_by_cust)

    grped_by_cust.each do |customer, late_lis|

      # there are 36 line items from 2006 that point to a non-existant order 
      next unless customer

      # these funcs both write to the global variable @@results
      if customer.in_last_chargeable_week?
        lost_dvd_onecust(customer, late_lis, :because_cc_expiring => true )
      else
        late_dvd_onecust(customer, late_lis)
      end
    end
    
    print_summary( "Weekly Late Charges")

  end

  def self.pending_list_failed
      failedCount = 0
      @@LOGGER.info "List of payments pending but failed (complete but not successful):"
      Payment.find_all_by_status_and_complete_and_successful(Payment::PAYMENT_STATUS_DEFERRED, true, false).each do |payment|
        failedCount += 1
        @@LOGGER.info " Payment # #{payment.id} for order # #{payment.order_id} failed."
      end
      @@LOGGER.info "Total pending failed payments = #{failedCount}"
  end

  def self.pending_list_open
      openCount = 0
      @@LOGGER.info "List of payments pending and open (incomplete):"
      Payment.find_all_by_status_and_complete(Payment::PAYMENT_STATUS_DEFERRED, false).each do |payment|
        openCount += 1
        @@LOGGER.info " Payment # #{payment.id} for order # #{payment.order_id} is incomplete."
      end
      @@LOGGER.info "Total pending open payments = #{openCount}"

  end

  def self.helper(text, order)
    order.reload
    puts   "  || #{text} order_id #{order.id}"
    order.payments.each do |pp|
      puts "  ||   *   #{pp.inspect}"
    end
    if order.payments.empty?
      puts "  ||   ...none"
    end
  end

  def self.pending_charge
    verbose = false

    payments_processed = 0
    payments_skipped_for_retry = 0
    payments_good = 0
    payments_bad = 0

    # Find all the orders which have payments with the "pending"
    # status, then deal with each:
    Payment.includes( { :order => :customer }).find_all_by_status_and_complete(Payment::PAYMENT_STATUS_DEFERRED, false).each do |payment|

      unless payment.order
        @@logger.call "ERROR: payment #{payment.id} has no order associated"
        next
      end
      unless payment.order.customer
        @@logger.call "ERROR: payment #{payment.id} has order #{payment.order.id} but order has no customer"
        next
      end

      order = payment.order
      helper("BEFORE", order) if verbose

      # don't charge too often - payment.chargeable?() 
      # has a schedule for how often we can attempt to process deferred payments
      if ! payment.chargeable?
        puts "YYY-1 skipping - payment not chargeable" if verbose
        payments_skipped_for_retry += 1
        next
      end

      unless payment.order.chargeable?
        puts "YYY-2 skipping - order not chargeable" if verbose
        payments_skipped_for_retry += 1
        next
      end
      puts "YYY-3 going - #{payment.order.payments.size} payments" if verbose

      success, details = ChargeEngine.charge_customer(payment.customer, 
                                                      payment.amount_as_new_revenue,
                                                      payment.order.id, 
                                                      "Charge for order # #{payment.order.id}")
      helper("IMMEDIATELY AFTER", order) if verbose

      puts "YYY-4 afterwards #{success} // #{details} // #{payment.order.payments.size}" if verbose

      # this counter is used by payment.chargeable?() - see comment above
      payment.increment!(:retry_attempts)

      payments_processed += 1

      if success
        puts "YYY-5a success-1" if verbose
        payments_good += 1
        # now we've got two payments ... wrong!

        old_payment = payment.order.payments.first
        new_payment = payment.order.payments.last

        payment.update_attributes!(:status => Payment::PAYMENT_STATUS_DEFERRED_RESOLVED)

        puts "YYY-5b success-2" if verbose
      else
        puts "YYY-5c failure" if verbose
        payments_bad += 1
        SfMailer.simple_message(payment.customer.email, 
                               SmartFlix::Application::EMAIL_FROM, 
                               "Your order # #{payment.order.id} at Smartflix has failed.", 
                               "Your charge attempt failed due to #{details}.  Please retry your order.")
      end

      helper("LATER", order) if verbose



    end

    
    @@logger.call " * charge_pending execute: #{payments_processed} charges processed."
    @@logger.call " * charge_pending execute: #{payments_bad} charges completed, failed."
    @@logger.call " * charge_pending execute: #{payments_good} charges completed, success."
  end

  # If for each order, see if 
  #   (a) it's a univ order
  #   (b) the CC is about to expire, thus necessitating either a charge or a warning
  #
  # returns an array
  #    [ lost_charges, warnings_issued ]
  def self.ping_univ_for_near_expired_cc(order, customer, active)

      lost_charges = 
      warnings_issued = 
      0
    
    # lis_in_field = order.line_items_in_field_good
    # puts "a: #{active} // 2m: #{customer.in_last_two_chargeable_months?} // 2w: #{customer.in_last_chargeable_week?(2)} // li: #{lis_in_field.any?} // #{Date.today.wday} "
    return [0, 0] if ! active
    return [0, 0] if ! customer.in_last_two_chargeable_months?
    
    lis_in_field = order.line_items_in_field_good
    
    cid = customer.id

    if customer.in_last_chargeable_week?(2) && lis_in_field.any?
      @@logger.call "  customer # #{cid} - bill lost"
      #--
      # charge - email gets sent down below
      
      lost_dvd_onecust(customer, lis_in_field, {:because_cc_expiring => true } ) 
      ScheduledEmail.note_emails_sent(customer, :univ_expire_cc_charge, { :lis => lis_in_field })
      
      lost_charges += 1
      
    elsif Date.today.wday == 1 
      @@logger.call "  customer # #{cid} - warn CC"
      #--
      # warn
      
      SfMailer.cc_expire_warn_univ(:customer => customer, 
                                         :order => order,
                                         :copies => lis_in_field.map(&:copy) ,
                                         :details => "")
      ScheduledEmail.note_emails_sent(customer, :univ_expire_cc_warn, { :lis => lis_in_field })
      
      warnings_issued += 1
    else
      @@logger.call "  customer # #{cid} - could warn CC, but not wday == 1 (#{Date.today.wday})" 
    end

    return lost_charges, warnings_issued
  end

  def self.bill_univ_students
    total_charges = 0.0

    not_active      = 0
    no_live_cc      = 0
    fees_current    = 0
    charged         = 0
    credit_used     = 0
    warnings_issued = 0
    lost_charges    = 0
    
    University.find(:all).each do |university|
      @@logger.call "Charges for #{university.name}:"
      
      Order.find_all_by_university_id(university.id).each do |order|
        
        # avoid broken data
        next if order.customer_id == 0

        customer = order.customer
        cid = sprintf "%7i", customer.customer_id

        # definition of when we should charge a customer:
        #   * they've got dvds in the field
        #           -- or --
        #   * they have a live order (with or without items in the queue)
        #     and they're not throttled
        #
        #    items-in-field    orderlive/uncancelled     !throttled     charge?
        # ----------------------------------------------------------------------
        #       yes                   *                     *          yes - of course!
        #       no                    yes                   yes        yes - they should add items!
        #       no                    yes                   no         no  - on vacation
        #       no                    no                    *          no  - they cancelled
        #
        active = (order.any_in_field? || (order.live && ! customer.throttleP))

        #-----
        # soon expiring CC?  Warn customer / charge them for lost DVDs
        #-----

        new_lost, new_warns = self.ping_univ_for_near_expired_cc(order, customer, active)

        # ...if we've just charged them for lost DVDs, we don't want to also bill them for
        # a month of the univ, nor do we want to ping them for a low queue, etc. 
        active = false if new_lost > 0

        warnings_issued += new_warns
        lost_charges    += new_lost

        #-----
        # do billing (or not)
        #-----

        if ! active
          #-----
          # not active
          #
          @@logger.call "  customer # #{cid} - not active"
          not_active += 1          
        elsif order.univ_fees_current?
          #-----
          # current
          #
          @@logger.call "  customer # #{cid} - fees current"
          fees_current += 1
        else
          #-----
          # bill the customer
          # 
          if customer.credit_months > 0
            #-----
            # bill: use acct credit (months)
            #
            customer.subtract_account_credit(nil, nil, 1)
            order.payments << Payment.create!( :amount => order.univ_subscription_charge,
                             :amount_as_new_revenue => 0.00,
                             :complete => 1,
                             :successful => 1,
                             :updated_at => Time.now(),
                             :payment_method => "Account Credit",
                             :message => "1 month of account credit",
                             :customer => customer)
            success = true
            details = "used month account credit"
            credit_used += 1
          elsif customer.credit.to_f > order.univ_subscription_charge
            #-----
            # bill: use acct credit (dollars)
            #
            customer.subtract_account_credit(nil, order.univ_subscription_charge , 0)
            order.payments << Payment.create!( :amount => order.univ_subscription_charge,
                             :amount_as_new_revenue => 0.00,
                             :complete => 1,
                             :successful => 1,
                             :updated_at => Time.now(),
                             :payment_method => "Account Credit",
                             :message => "1 month of account credit - via dollars",
                             :customer => customer)
            success = true
            details = "used dollar account credit"
            credit_used += 1
          else
            #-----
            # bill: use credit card
            #

            bill_amount = order.univ_subscription_charge
            if order.payments.size == 1 && 
                order.payments.first.status == Payment::PAYMENT_STATUS_RECURRING &&
                ! order.payments.first.complete
              bill_amount = order.payments.first.amount
            end


            success, details = ChargeEngine.charge_customer(customer, 
                                                            bill_amount, 
                                                            order.id, 
                                                          "university charge")
            if success
              charged += 1
            else
              no_live_cc += 1
            end

            if success
              total_charges += order.univ_subscription_charge
              if order.line_items_unshipped_and_uncancelled.size < 6
                SfMailer.univ_queue_low(customer, order)
                
              end

            elsif  ! success && (Date.today.wday == 1)
              
              SfMailer.unpaid_univ(:customer => customer, 
                                         :order => order,
                                         :copies => order.line_items_in_field.map(&:copy) ,
                                         :details => details)
            end

          end
          @@logger.call "  customer # #{cid} - #{ success ? "charged" : "failed"} #{details}"
        end
      end # one order
    end # one univ

    @@logger.call "not active:    #{not_active}"
    @@logger.call "fees current:  #{fees_current}"
    @@logger.call "no live CC:    #{no_live_cc}"
    @@logger.call "charged:       #{charged}"
    @@logger.call "\n"
    @@logger.call "warnings:      #{warnings_issued}"
    @@logger.call "lost charges:  #{lost_charges}"
    @@logger.call ""
    @@logger.call "TOTAL REVENUE: #{total_charges}"

  end # func

end

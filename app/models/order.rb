# Define some custom exceptions that the order can throw
class DuplicateID < StandardError
end
class InvalidArguments < StandardError
end

class Order < ActiveRecord::Base
  self.primary_key = "order_id"

  attr_protected # <-- blank means total access

  
  belongs_to :customer
  belongs_to :university
  has_many   :ab_test_results, :as => :reference
  has_many   :chargeback_disputes
  has_many   :line_items
  has_many   :payments, :order => 'created_at DESC'
  has_many   :price_modifiers
  has_many   :products, :through => :line_items
  has_many   :survey_answers
  has_one    :tax
  has_many   :cancellation_logs, :as => :reference
  has_one    :upsell_offer, :foreign_key => 'upsell_order_id'
  
  # this next line implies
  #   1) "has_many univ_dvd_rate_updates"
  #   2) existance of class UnivDvdRateUpdate in file univ_dvd_rate_update.rb
  track_changes_on :univ_dvd_rate, :tracking_reference_columns => [], :allowed_references => []  

  scope :paid, :group => "orders.order_id", :joins => :payments, :conditions => "complete = 1 and successful = 1"
  scope :for_cust,     lambda { |cust| {  :conditions => "orders.customer_id = #{cust.customer_id}" }}
  scope :for_univ,     lambda { |univ_id| {  :conditions => "university_id = #{univ_id}" }}
  scope :for_univ_any,                       :conditions => "university_id" 
  scope :some_uncancelled, :joins => :line_items, :conditions => "orders.live", :group => "orders.order_id"
  scope :some_replacement, :joins => :line_items, :conditions => "parent_line_item_id", :group => "orders.order_id"
  scope :some_nonreplacement, :joins => :line_items, :conditions => "ISNULL(parent_line_item_id)" # , :group => "orders.order_id"

  scope :orders_for_cust_univ, lambda { |cust, univ| {  :conditions => "customer_id = #{cust.customer_id} AND university_id = #{univ}" }}



  delegate :shipping_address, :customs?, :to =>:customer

  def canada?() customer.shipping_address.canada? end

  #----------------------------------------
  # utility functions
  #----------------------------------------

  #-----
  # LIs
  #-----

  def line_items_unshipped_and_uncancelled_and_ignore_for_limits() line_items_unshipped_and_uncancelled.select {|li| li.ignore_for_univ_limits} end
  def line_items_unshipped_and_uncancelled()      line_items.select { |li| li.live && li.shipment.nil? }  end
  def line_items_unshipped()                      line_items.reject { |li| li.shipped? }  end
  def line_items_uncancelled()                    line_items.select { |li| li.live}  end
  def line_items_shipped()                        line_items.select { |li| li.shipment }  end
  def line_items_in_field_lost()                  LineItem.for_order(self).in_field.copy_lost  end
  def line_items_in_field_good_and_count()        LineItem.for_order(self).in_field.copy_good.ignore_for_univ_limits(false)  end
  def line_items_in_field_good()                  LineItem.for_order(self).in_field.copy_good  end
  def line_items_in_field()                       LineItem.for_order(self).in_field  end
  def line_items_cancelled()                      line_items.select { |li| ! li.live}  end
  def line_items_back()                           line_items.select { |li| li.back? }  end
  def line_items_pending()                        line_items.select { |line_item| line_item.pending? } end
  def line_items_pending_any?()                   line_items.any? { |line_item| line_item.pending? } end


  def any_in_field?()                             line_items_in_field_good.any? end



  def shipments()                                 line_items_shipped.map(&:shipment).uniq end


  def products_unshipped_and_uncancelled()      
    line_items_unshipped_and_uncancelled.map(&:product)
  end

  def backend?
    server_name == "backend"
  end

  def lis_shipped_between(start, finish)
    line_items.select { |li| li.dateOut && li.dateOut >= start && li.dateOut <= finish}
  end

  def lis_shipped_between_nonignored(start, finish)
    lis_shipped_between(start, finish).select { |li| li.ignore_for_univ_limits == false }
  end

  

  def chargeable?()                               line_items_unshipped_and_uncancelled.any?  end
  
  def revenue
    self.line_items_uncancelled.inject(BigDecimal('0.0')) { |sum, li| sum + li.price }
  end

  def profit
    revenue / 2 
  end

  # Get the total for this order by adding up all line items and price modifiers
  def total
    sum = self.line_items.inject(BigDecimal('0.0')) { |sum, li| sum + li.price } +
      self.price_modifiers.inject(BigDecimal('0.0')) { |sum, pm| sum + pm.amount }
    return ApplicationHelper.round_currency(sum)
  end
  
  # Get the sub total for this order by adding up all line items
  def sub_total
    return ApplicationHelper.round_currency(self.line_items.inject(BigDecimal('0.0')) { |sum, li| sum + li.price })
  end
  
  def date
    orderDate.to_date
  end
  
  def date_cancelled
    dates = line_items.map(&:dateCancelled)
    return nil if dates.detect { |date| date.nil?}
  end

  #----------
  # univ misc functions
  #----------

  def name
    university && university.name
  end

  def counts?
    line_items.first.andand.ignore_for_univ_limits
  end

  def ignore_lis
    LineItem.for_order(self).ignore_for_univ_limits(true)
  end

  def ignore_lis_count
    ignore_lis.count
  end

  def counts_lis
    LineItem.for_order(self).ignore_for_univ_limits(false)
  end

  def counts_lis_count
    counts_lis.count
  end

  def normalize_sort_order
    return unless university_id

    ii = 1
    lis = line_items_pending.sort_by { |li| li.queue_position || li.line_item_id }
    lis.each do |li|
      li.update_attributes(:queue_position => ii) 
      ii+= 1 
    end
    
    line_items_cancelled.each { |li| li.update_attributes(:queue_position => nil) }

    self
  end

  # we could speed this up with
  # scopes, SQL, etc.
  def can_add_product(p)                         
    university_id && 
      ! products_unshipped_and_uncancelled.include?(p) &&
      ( ! p.premium? ||  univ_premium? )  # we can add non-prem products to any univ, or premium prods to premium univs
  end
    

  def univ_dvd_rate_history
    return [] unless university_id

    # we've got 
    #  1) the end state
    #  2) the deltas and when they were applied
    # generate a first pass
    changes = univ_dvd_rate_updates
    changes = changes.map { |ch| { :created_at => ch.created_at, :delta  => ch.univ_dvd_rate } }

    total = univ_dvd_rate
    history = []
    
    history << { :created_at => nil, :univ_dvd_rate => univ_dvd_rate }

    changes.reverse.each { |pair| total -= pair[:delta] ;  history << {  :created_at => pair[:created_at], :univ_dvd_rate => total } }
    
    # OK, now we've got the timestamps all a bit off - if we were at
    # state N up till Monday and then at N+1 thereafter, we've got the
    # "Monday" timestamp on the creation of the N state.  Swizzle all
    # the timestamps.
 
    history = history.reverse.map_with_trailing { |item, trail| { :univ_dvd_rate => item[:univ_dvd_rate] , :created_at => trail.andand[:created_at]} }
    history[0][:created_at] = created_at

    # ... I note that clever use of the map_with_trailing could prob
    # do all of this in 1 pass, not 2 ... but I can't summon up the
    # clever today.  :-(

    history
  end
  
  def univ_and_counts
    (university_id && line_items.any? && line_items.detect{|li| ! li.ignore_for_univ_limits}).to_bool
  end

  def univ_add_product(product)
    raise "not univ" unless university_id
    li = LineItem.for_product(product, 0.00, nil, true, order_id)
  end

  def univ_premium?
    university.andand.premium?.to_bool
  end

  #----------
  # univ payment functions
  #----------


  def num_good_univ_payments
    university_id && payments.select { |payment| payment.good?}.size
  end

  # are there any pending in this univ?
  #
  def university_pending?
    university && line_items_pending_any?
  end
  
  # does this university count as live at a certain date?
  #
  # XYZFIX P2: need to consider credit card / payment viability - 
  # if a credit card expires on 30 Jan 2008, and we don't ship the remaining 10 items,
  # we don't want to consider the order as a live university order until the end of time!
  #
  def live_university_at?(query_date = Date.today)
    # if a cust has 3 dvds in the field and cancels, we want that to count as a cancelled order
    university && (line_items.select { |li| li.live_at(query_date) }.size > 3) && univ_payed_up?
  end

  def items_but_unpaid()
    university && (line_items.select { |li| li.live_at(query_date) }.size > 3) && ! univ_payed_up?
  end
  
  def univ_month_begin
    university_id && most_recent_payment.andand.created_at.andand.to_date
  end
  def univ_month_end
    university_id && ((univ_month_begin >> 1) - 1)
  end

  def univ_month_begin_next
    return nil unless most_recent_payment
    ( university_id && most_recent_payment.andand.created_at.andand.to_date ) >> 1
  end
  
  # what's the setting for your dvd rate?
  #
  def univ_dvd_rate_str  
    count = univ_dvd_rate
    "#{count} #{'DVD'.pluralize_conditional(count)} per month"    
  end

  # ...and what have you PAID for ?
  def univ_paid_ship_rate
    return 0 unless most_recent_payment_good && university_id
    university.number_per_month(most_recent_payment_good.andand.amount)
  end
  
  def univ_paid_ship_rate_str
    count = univ_paid_ship_rate
    "#{count} #{'DVD'.pluralize_conditional(count)} per month"    
  end

  #
  #
  def move_univ_month_n_days(n)
    raise "not univ" unless university_id
    pp = payments.first

#    begin
#      ActiveRecord::Base.record_timestamps = false
#      pp.updated_at = pp.updated_at + n.days
#      pp.save!
#    ensure
#      ActiveRecord::Base.record_timestamps = true
#    end

    datetime_str = (pp.updated_at + n.days).strftime("%Y-%m-%d %H:%M:%S")
    pp.connection.execute("update payments set updated_at = '#{datetime_str}' where payment_id = #{pp.payment_id}")

    pp.reload
    pp.updated_at
  end

  #----------
  # payment
  #----------

  def paid?()                   
    backend? || 
      payments.detect { |payment| payment.good?}  
  end

  def payment_complete?()        payments.detect { |payment| payment.complete?}  end
  
  def most_recent_payment()      self.payments.max_by{|x| x.created_at || DateTime.parse("1900-01-01")}  end
  def most_recent_payment_good() self.payments.select {|x| x.good?}.max_by{|x| x.created_at || DateTime.parse("1900-01-01")}  end
  
  def univ_fees_current?()
    raise "not a university" if ! university
    return true if 
    ret = most_recent_payment && 
      most_recent_payment.created_at  &&
      (most_recent_payment.created_at.to_date > (Date.today << 1)) &&
      most_recent_payment.successful
    ret.to_bool
  end

  def univ_fees_good_enough?()
    raise "not a university" if ! university

    # paid up
    univ_fees_current? || 
      
      # first month free
      (payments.size == 1 && payments.first.complete == false)  ||

      # customer update CC just now
      customer.credit_cards.any? && (customer.credit_cards.max_by(&:created_at).created_at.to_date == Date.today)
  end

  
  # The charge_pending task does not charge recurring charges (like universities).
  #
  # Thus, if 
  #   1) we discount the initial month via an A/B test, or coupon
  #   2) customer uses stored credit card, meaning that we use deferred charging
  # then we want to charge the actual amount to be the discounted monthly amount.
  #
  def univ_fee_amount_to_charge()
    raise "not a university" if ! university
    payments.select(&:good?).empty? ? payments.first.amount : university.subscription_charge_for_n(univ_dvd_rate)
  end
  
  def univ_subscription_charge()
    ret = university && university.subscription_charge_for_n(univ_dvd_rate)
  end

  UNIV_STATUS_TYPES = [:live,
                       :live_unpaid,
                       :live_unpaid_in_field,
                       :cancelled_full,
                       :cancelled_in_field]

  #----------------------------------------
  # 
  #----------------------------------------

  def univ_status
    if live
      return :live if univ_fees_current?
      return line_items_in_field_good.any? ? :live_unpaid_in_field : :live_unpaid
    else
      return line_items_in_field_good.any? ? :cancelled_in_field : :cancelled_full
    end
  end
  
  #----------------------------------------
  # display functions
  #----------------------------------------
  
  def live_products_as_sentence
    line_items.reject { |li| li.cancelled? }.map{|li| li.product.name}.to_sentence
  end
  
  # Get a string for the date / time as it should be displayed
  def listing_date()    self.created_at.strftime('%a %b %d, %Y')  end
  def listing_time()    self.created_at.strftime('%a %b %d, %Y  %H:%M')  end
  
  #----------------------------------------
  # datamining
  #----------------------------------------
  
  def newsletter()    Newsletter.find($1) if origin_code.match(/smnl([0-9]+)/)  end
  def google_ad()    AdwordsAd.find($1) if origin_code.match(/ADID=([0-9]+)/)  end
  
  # Did this order come to us because the customer browsed X and then we sent them email?
  def browsed?()    origin_code == "browsed"  end
  
  #------------------------------
  # payments
  #------------------------------
  
  
  # Get a string for the payment method, as it should be displayed
  def payment_method
    self.payments.last.andand.payment_method  || "none"
  end
  
  def report_status_for_display
    last_payment = self.payments.last
    if last_payment.nil?
      "<font color='red'><b>error</b></font> - no payment !!"
    elsif ( ! last_payment.complete)
      "in process"
    else 
      last_payment.successful ? "successful" : "failed"
    end
  end
  
  
  
  # is this an entirely unshippable order that we need to be worried about (i.e. alert the customer) ?
  # if it's got zero live items, then the answer is "no" (a bit odd logically, but the business logic makes sense)
  def entirely_unshipped?
    line_items_uncancelled.empty?.not && line_items_uncancelled.detect {|li| ! li.shipment.nil? }.nil?
  end
  
  def total_price
    line_items_uncancelled.inject(0){ |sum, li| sum+= li.price}.to_f
  end
  
  def total_rental_price
    ( late? || replacement? ) ? 0.0 : total_price
  end
  
  def univ_any_payments?
    # if we've just created a univ order and haven't yet tried to charge it, respond FALSE
    # if we've tried (maybe succeeded, maybe not) one or more times, respond TRUE
    return false unless university    
    payments.select { |payment| payment.complete }.any?
  end
  
  def univ_payed_up?
    return false unless university
    payments.reverse.any? { |payment| (payment.updated_at.to_date >> 1) > Date.today && payment.good? }
  end
  
  
  #----------------------------------------
  # backend orders 
  #----------------------------------------
  
  private  

  # for admin tools - create an order and a fake payment
  #
  def self.create_backend_order_internal(customer, university = nil)
    new_order = Order.create!(:orderDate => Date.today.to_s, 
                              :customer => customer, 
                              :server_name => "backend",
                              :univ_dvd_rate => university ? 3 : nil,
                              :university => university
                              )
    new_payment = Payment.create!(:amount => 0.00,
                                  :amount_as_new_revenue => 0.00,
                                  :complete => 1,
                                  :successful => 1,
                                  :updated_at => Time.now(),
                                  :payment_method => "backend",
                                  :message => "fake payment for backend order" ,
                                  :customer => customer)
    new_order.payments << new_payment
    new_order
  end

  public

  # for admin tools - create an order and a fake payment (simple case)
  #
  def self.create_backend_order(customer, products)
    new_order = create_backend_order_internal(customer)
    products.each { |product| LineItem.create(:product => product, :order => new_order, :price => product.price)    }
    new_order
  end

  # for admin tools - create multiple orders and payments (complicated
  # case - a list of LIs that can span multiple orders, some in unis,
  # some not, etc. )
  #
  def self.create_backend_replacement_order(customer, line_items_to_replace)
    new_orders = []
    line_items_to_replace.group_by { |li| li.order.university }.each_pair do |university, old_lis| 

      new_order = create_backend_order_internal(customer, university)

      old_lis.each do |old_li|
        li = LineItem.create(:product_id => old_li.product_id, 
                             :order => new_order,
                             :price => 0.0,
                             :ignore_for_univ_limits => university.to_bool,
                             :parent_line_item_id => old_li.id)
      end
      new_orders << new_order
    end
    new_orders
  end

  #----------------------------------------
  # backend ops
  #----------------------------------------

private
  def change_liveness(liveness)
    LineItem.transaction do
      update_attributes(:live => liveness)
      CancellationLog.create!(:new_liveness => liveness, :reference => self)
    end
  end
public
  
  def cancel(force = false)
    line_items_unshipped_and_uncancelled.each{|li| li.cancel(force)}
    change_liveness(false)
  end
  
  def reinstate
    update_attributes(:live => true)

    lis = line_items_cancelled
    # if customer cancelled some items on 1 Jan, then cancelled the univ on 15 Jan,
    # if we uncancell the univ on 20 Jan, we don't want to reinstate all LIs, just
    # the ones cancelled in the last step
    recently_cancelled_lis = lis.select {|li| li.updated_at >= lis.max_by(&:updated_at).updated_at - 15 }
    
    recently_cancelled_lis.each{|li| 
      next unless li.uncancellable?
      li.uncancel
    }
    change_liveness(true)    

  end

  unless Rails.env == 'production'
    # in testing we sometimes want to get rid of an order
    def destroy_all
      destroy_self_and_children([:line_items, :payments])
    end
  end
  
  # needed this for 1-time use when customers got charged for stuff, error threw, orders
  # didn't get stored to db.
  #
  # Use from console thusly:
  #    create_frontend_order("xxx", "Xxx", [124, 5501])
  # if multiple customers found, each has his shipping addr printed out, then reuse thusly:
  #    create_frontend_order("xxx", "Xxx", [124, 5501], 3 )
  #
  def self.create_frontend_order(first_name, last_name, product_ids, which_cust = nil)
    custs = Customer.find_all_by_first_name_and_last_name(first_name, last_name)
    raise "fail - none" if custs.empty?
    if custs.size > 1
      if which_cust
        cust = custs[which_cust]
      else
        custs.each_with_index do |cust, index|
        end 
        raise "fail - too many" 
      end
    else
      cust = custs.first
    end
    
    o = Order.create(:customer => cust, 
                     :orderDate => Date.today.to_s,
                     :server_name => "smartflix.com")
    raise "order failed" unless o
    
    
    payment = Payment.create(:order => o,
                             :amount => 9.99 * product_ids.size,
                             :amount_as_new_revenue => 9.99 * product_ids.size,
                             :complete => 1,
                             :successful => 1,
                             :updated_at => Time.now(),
                             :payment_method => "Credit Card",
                             :customer => cust)
    raise "payment failed" unless payment      
    
    product_ids.each do |product_id|
      LineItem.create!(:order => o, :product_id => product_id, :price => Product.find(product_id).price)
    end
    o
  end
  
  def self.note_foo_charge(customer, line_items, price_func, server_name)
    # build order and lineitem; mark copies as dead
    #
    # possible incompatibilities with lineitem
    #   - copy can be out twice: once original, and once again now
    #   - dateBack is a bit of a lie
    #   - return_email_sent is a bit of a lie (to avoid sending a "we got it back" email)
    # possible incompatibilities with shipment
    #   - boxP is a lie
    
    order = Order.create!(:orderDate => Date.today.to_s, :customer => customer, :server_name => server_name)
    line_items.each do |old_line_item|
      li = LineItem.create!(:product => old_line_item.product, 
                           :order => order,
                           :price => old_line_item.product.send(price_func), 
                           # XYZFIX P1 - would be nice to record this    :copy  => old_line_item.copy,
                           :actionable => false,
                           :parent_line_item_id => old_line_item.id)
    end
    
    # insert at website via REST ; ignore return value
    # XYZ FIX P2: turn this on.  We need server_name and price, though.
    # RcadminRequest.insert_order(order)
    
    order
  end
  
  def self.note_lost_charge(customer, line_items)
    note_foo_charge(customer, line_items, :replacement_price, "replacement charge")
  end
  
  def self.note_late_charge(customer, line_items)
    note_foo_charge(customer, line_items, :late_price, "late charge")
  end
  
  #----------------------------------------
  # Stats
  #----------------------------------------
  
  def self.via_newsletter(fday, lday, just_countP = false)
    find_by_sql("SELECT #{(just_countP ? "count(1) as cnt" : "*")} 
                 FROM orders
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND origin_code like 'smnl%'")
  end

  # XYZFIX P3: duplicates above code
  def self.revenue_via_newsletter(fday, lday)
    find_by_sql("SELECT sum(price) as revenue
                 FROM orders, line_items
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND origin_code like 'smnl%'
                 AND orders.order_id = line_items.order_id")[0]['revenue'].to_f
  end

  def self.via_googlead(fday, lday, just_countP = false)
    find_by_sql("SELECT #{(just_countP ? "count(1) as cnt" : "*")} 
                 FROM orders
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND origin_code like 'gac%'")
  end

  # XYZFIX P3: duplicates above code
  def self.revenue_via_googlead(fday, lday)
    find_by_sql("SELECT sum(price) as revenue
                 FROM orders, line_items
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND origin_code like 'gac%'
                 AND orders.order_id = line_items.order_id")[0]['revenue'].to_f
  end

  def self.via_affiliate(fday, lday, just_countP = false)
    find_by_sql("SELECT #{(just_countP ? "count(1) as cnt" : "*")} 
                 FROM orders
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND origin_code like 'af%'")
  end

  # XYZFIX P3: duplicates above code
  def self.revenue_via_affiliate(fday, lday)
    find_by_sql("SELECT sum(price) as revenue
                 FROM orders, line_items
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND origin_code like 'af%'
                 AND orders.order_id = line_items.order_id")[0]['revenue'].to_f
  end

  def self.via_other_online_ad(fday, lday, just_countP = false)
    find_by_sql("SELECT #{(just_countP ? "count(1) as cnt" : "*")} 
                 FROM orders
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND !ISNULL(origin_code)
                 AND origin_code NOT LIKE 'af%'
                 AND origin_code NOT LIKE 'gac%'
                 AND origin_code NOT LIKE 'smnl%'")
  end

  # XYZFIX P3: duplicates above code
  def self.revenue_via_other_online_ad(fday, lday)
    find_by_sql("SELECT sum(price) as revenue
                 FROM orders, line_items
                 WHERE orderDate >= '#{fday} '
                 AND orderDate <= '#{lday}'
                 AND !ISNULL(origin_code)
                 AND origin_code NOT LIKE 'af%'
                 AND origin_code NOT LIKE 'gac%'
                 AND origin_code NOT LIKE 'smnl%'
                 AND orders.order_id = line_items.order_id")[0]['revenue'].to_f
  end

  def self.orders_from_cat(fday, lday, cat_id)
    find_by_sql("SELECT count(distinct(orders.order_id)) as cnt 
                 FROM  categories, categories_products, line_items, orders
                 WHERE (categories.category_id = #{cat_id} || categories.parent_id = #{cat_id} )
                 AND   categories.category_id = categories_products.category_id
                 AND   categories_products.product_id = line_items.product_id
                 AND   line_items.order_id = orders.order_id
                 AND   orders.orderDate >= '#{fday}'
                 AND   orders.orderDate <= '#{lday}'").first["cnt"].to_i
  end


  def self.orders_from_custs_of_this_period(fday, lday)  
    find_by_sql("SELECT orders.* 
                 FROM orders, customer
                 WHERE orders.customer_id = customers.customer_id
                 AND   DATE(customers.railscart_created_at) >= '#{fday}'
	             AND   DATE(customers.railscart_created_at) <= '#{lday}'
	             AND   orders.orderDate >= '#{fday}'
	             AND   orders.orderDate <= '#{lday}'")
  end
  

  def self.orders_from_custs_of_prev_period(fday, lday)  
    find_by_sql("SELECT orders.* 
                 FROM orders, customer
                 WHERE orders.customer_id = customers.customer_id
                 AND   DATE(customers.railscart_created_at) < '#{fday}'
                 AND   orders.orderDate >= '#{fday}'
                 AND   orders.orderDate <= '#{lday}'")
  end

  def self.revenue_from_custs_of_this_period(fday, lday)  
    find_by_sql("SELECT sum(price) as revenue
                 FROM orders, customers, line_items
                 WHERE orders.customer_id = customers.customer_id
                 AND   line_items.order_id = orders.order_id
                 AND   line_items.live = 1
                 AND   DATE(customers.railscart_created_at) >= '#{fday}'
                 AND   DATE(customers.railscart_created_at) <= '#{lday}'
                 AND   orders.orderDate >= '#{fday}'
                 AND   orders.orderDate <= '#{lday}'")[0]["revenue"]
  end

  def self.revenue_from_custs_of_prev_period(fday, lday)  
    find_by_sql("SELECT sum(price) as revenue
                 FROM orders, customers, line_items
                 WHERE orders.customer_id = customers.customer_id
                 AND   line_items.live = 1
                 AND   line_items.order_id = orders.order_id
                 AND   DATE(customers.railscart_created_at) < '#{fday}'
                 AND   orders.orderDate >= '#{fday}'
                 AND   orders.orderDate <= '#{lday}'")[0]["revenue"]
  end


  
  def self.STATS_revenue_of_type_x(fday, lday, charge_type)
    # This is a bit tricky.
    #
    # Back in the good old days, we could just look at the prices on
    # line_itemss from a given interval.
    #
    # Then we added SmartFlix universities, which don't put prices on
    # line_itemss - they have 1 order, a bunch of zero-cost line_itemss,
    # and monthly payments hanging off the order that have prices.
    #
    # Also, :lost and :replacement charges are done on the backend and don't have associated payment objects.
    #
    # So, it's a bit of a mess, but the following works:
    #
    if (charge_type == :university)
      row =  Order.connection.select_all("SELECT sum(amount_as_new_revenue) as total from payments, orders
                                          WHERE payments.order_id = orders.order_id
                                          AND payments.updated_at >= \"#{fday.to_s}\"
                                          AND payments.updated_at <= \"#{lday.to_s}\"
                                          AND  #{charge_type_sql(charge_type)}
                                          AND complete = 1 
                                          AND successful = 1")
    else
      row =  Order.connection.select_all(
              "SELECT SUM(IF(pay_total > 0, pay_total, li_total)) as total
               FROM
                   (SELECT orders.order_id, sum(price) as li_total
                   FROM orders, line_items
                   WHERE orders.order_id = line_items.order_id
                   AND orders.orderDate >= \"#{fday.to_s}\"
                   AND orders.orderDate <= \"#{lday.to_s}\"
                   AND line_items.live = 1
                   AND  #{charge_type_sql(charge_type)}
                   GROUP BY (orders.order_id)) li_data
               LEFT JOIN
                   (SELECT orders.order_id, sum(amount_as_new_revenue) as pay_total 
                   FROM orders, payments
                   WHERE   payments.order_id = orders.order_id
                   AND orders.orderDate >= \"#{fday.to_s}\"
                   AND orders.orderDate <= \"#{lday.to_s}\"
                   AND complete = 1
                   AND successful = 1
                   AND  #{charge_type_sql(charge_type)}
                   GROUP BY (orders.order_id)) payment_data

               ON li_data.order_id = payment_data.order_id") 

    end
    row[0]["total"].to_f
  end

  def self.ERRORCHECK_order_date
    find_by_sql("SELECT * from orders where ISNULL(orderDate)")
  end

  def self.ERRORCHECK_payments_exist
    find_by_sql("select * from (select orders.*, payments.payment_id from orders left join payments on orders.order_id = payments.order_id where server_name = 'backend') zzz where ISNULL(payment_id)")
  end


  #------------------------------
  # class methods
  #------------------------------

  # Create an order from a university id. (for Smartflix U/subscription functionality)
  def self.subscribe_to_university_curriculum(university, customer, how_many_dvds = 3)

    order = self.create!(:university => university, :customer => customer, :orderDate => Date.today)
    order.set_univ_dvd_rate(how_many_dvds)
    order.save!

    bindle = UniversityCurriculumElement.find_all_by_university_id(university.id, :order => 'university_curriculum_element_id')

    already_ordered_product_ids = customer.uncancelled_and_actionable_line_items.map(&:product_id)
    bindle.map(&:video_id).each do |product_id|

      already_ordered = already_ordered_product_ids.include?(product_id)

      order.line_items << LineItem.for_product(product_id, 0.0, nil, ! already_ordered, order.order_id) 
    end

    order
  end

  # Create an order from the to-buy contents of a shopping cart
  def self.for_cart(cart)

    order = self.create!(:orderDate => Date.today)
    CartGroup.groups_for_items(cart.items_to_buy, :discount => cart.global_discount).each do |group|
      group.items_with_prices do |item, price|
        order.line_items << LineItem.for_product(item.product, 
                             price - (item.discount ? item.discount : BigDecimal("0.0")),
                             nil,
                             true,
                             order.id)
      end
    end

    return order

  end

#   # Create an order given specific order and line item IDs to use, used
#   # for remote order insertion; exceptions raised if product not found
#   # or if specified IDs already exist
#
#   def self.for_remote_insert(customer_id, order_id, line_item_hash, ip_address)
#
#     raise InvalidArguments if customer_id.nil? || order_id.nil? || line_item_hash.nil? || !line_item_hash.is_a?(Hash)
#
#     raise DuplicateID, "OrderID #{order_id} already used" if Order.find_by_order_id(order_id)
#
#     order = self.new
#
#     line_item_hash.each do |line_item_id, product_id|
#       raise DuplicateID, "LineItemID #{line_item_id} already used" if LineItem.find_by_line_item_id(line_item_id)
#       line_item = LineItem.for_product(Product.find(product_id), 0.00)
#       order.line_items << line_item
#       line_item.id = line_item_id
#     end
#
#     order.id = order_id
#     order.customer = Customer.find(customer_id)
#     order.ip_address = ip_address
#
#     return order
#
#   end

  def self.university_orders
    Order.find(:all, :conditions => "university_id", :include => [ :payments ] )
  end
  
  def self.live_university_orders(query_date = Date.today)
    university_orders.select { |order| order.live_university_at?(query_date) }
  end
  
  def self.live_university_count(query_date = Date.today)
    live_university_orders(query_date).size
  end

  def self.live_university_count_and_revenue(query_date = Date.today)
    luo = live_university_orders(query_date)
    month = luo.inject(0) { |sum, order| sum + order.university.subscription_charge_for_n(order.univ_dvd_rate) }
    "#{luo.size} // #{month.currency} // #{(month * 12).currency }"
  end

  #----------------------------------------
  # constants, meta-programming, etc. re: charge_types (rental / lost / late /...)
  #----------------------------------------

  # ATTN CODERS! you probably don't want to ever user this constant hash.
  # You instead want to use either 
  #   * charge_type()
  # or one of the utility funcs:
  #   * rental?()
  #   * replacement?()
  #   * etc.
  
  private
  
  # XYZFIX P2: in railscart, orders have an extra field called univ-id that
  # is a better way to achieve this
  SERVERNAME_TO_TYPE = { 
    /late charge/              => :late,
    /replacement charge/       => :replacement,
    /smartflix.com/            => :rental,    # yes, this does include cobrands
    /backend.*/                  => :backend }  # ...but note that other backend tools put "NULL" here...
  public
  
  SERVERNAME_TO_TYPE.each_pair do |regexp, type| 
    define_method(type.to_s + "?") { 
      ((! server_name.nil? && ! server_name.match(regexp).nil?) ||
      (server_name.nil?   && type == :rental))
    }

   TYPE_TO_STRING = SERVERNAME_TO_TYPE.invert   unless defined?(TYPE_TO_STRING)

    def lost?() replacement? end

  end
  def university?
    charge_type == :university
  end
  
  def self.charge_types() SERVERNAME_TO_TYPE.values end
  def self.charge_types_for_stats() (SERVERNAME_TO_TYPE.values << [ :university, :all]).flatten - [:backend] end
  def charge_type
    return :university if university_id
    return :backend if server_name.nil?
      SERVERNAME_TO_TYPE.each_pair { |regexp, type| return type if server_name.match(regexp)    }
    return :unknown
  end
  
  def match_charge_type(desired)
    return true if desired == :all
    desired == self.charge_type
  end
  
  # For use in stats controller, etc., where we need to munge massive 
  # quantities of data: return a snippet that, when used in a query that
  # touches the orders table, will return just the matching items
  def self.charge_type_sql(charge_type)
    # XYZFIX P1 university program
    ret = { :late        => "server_name = 'late charge'",
      :replacement => "server_name = 'replacement charge'",
      :rental      => "ISNULL(university_id) AND server_name != 'late charge' AND server_name != 'replacement charge'",
      :university  => "! ISNULL(university_id)",
      :backend     => "server_name = 'backend'",
      :unknown     => "0",  # XYZFIX 
      :all         => "1"}[charge_type]
    raise "unknown charge_type '#{charge_type}'" if ret.nil?
    ret
  end
  
  def matches_order_type?(type)   type == charge_type  end

  #----------------------------------------
  # datamining
  #----------------------------------------
  
  def self.find_by_interval(begin_date, end_date)
    Order.find(:all, :conditions => "orderDate >= '#{begin_date.to_s}' and orderDate <= '#{end_date.to_s}'")
  end
  
  def self.DATAMINE_correlate_returns_with_nextday_rentals
    # investigate correlation of number of returns on day N with rentals on day N+1
    # ...and check it across days (better "conversion" rate for returns on day X than Y?)  
    # If so, maybe send return emails only on good days?
    (0..6).each do |day_of_week|
      
      ret = StatArray.DATAMINE(:conn => Order.connection,
                               :sql => "SELECT returns, orders 
                                FROM (

                                FROM line_items 
                                WHERE DATE_FORMAT(dateBack, '%w') = #{day_of_week}
                                GROUP BY dateBack) zzz, (
                                SELECT orderDate, count(1) as orders 
                                FROM line_items, orders 
                                WHERE line_items.order_id = orders.order_id 
                                GROUP BY orderDate) yyy 
                                WHERE TO_DAYS(zzz.dateBack) + 1  = TO_DAYS(yyy.orderDate) ")
    end
  end
  
  
  
end

require 'date'
class Date
  # want to use a has_many / finder_sql bit here, but that only works
  # if Date inherits from ActiveRecord ...and it doesn't

  def orders
    Order.find_by_sql("SELECT * FROM orders o  WHERE orderDate = '#{self.to_s}'")
  end

  def univ_orders
    Order.find_by_sql("SELECT * FROM orders o  WHERE orderDate = '#{self.to_s}' and university_id")
  end

end


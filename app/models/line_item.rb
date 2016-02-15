class LineItem < ActiveRecord::Base
  self.primary_key = "line_item_id"
  attr_protected # <-- blank means total access

  
  LI_STATES = [:fee, :not_existing, :not_shipped, :in_field, :lost_in_field, :back, :cancelled]

  DAYS_BETWEEN_SEND_AND_LATEMSG1   = 17
  DAYS_BETWEEN_LATEMSG1_AND_CHARGE = 5
  DAYS_BETWEEN_CHARGE_AND_CHARGE   = 7
  DAYS_EXTRA_FOR_CANADA            = 14
  DAYS_EXTRA_FOR_APO               = 14
  
  belongs_to  :copy
  belongs_to  :intended_copy                 , :class_name => 'Copy', :foreign_key => 'copy_id_intended'
  belongs_to  :order
  belongs_to  :parent_li                     , :class_name => 'LineItem', :foreign_key => 'parent_line_item_id'
  belongs_to  :product
  belongs_to  :shipment

  delegate    :dateOut                       , :to => :shipment  
  delegate    :email                         , :to => :customer
  delegate    :name                          , :to => :product
  delegate    :name                          , :to => :product  
  delegate    :server_name                   , :orderDate, :university_id, :to => :order  

  has_many    :cancellation_logs             , :as => :reference
  has_many    :children_lis                  , :class_name => 'LineItem', :foreign_key => 'parent_line_item_id'
  has_many    :payments                      , :through => :order

  has_one     :customer                      , :through => :order
  has_one     :potential_item

  scope :copy_good                     , :joins => [:copy], :conditions => "status = 1"
  scope :copy_lost                     , :joins => [:copy], :conditions => "(death_type_id = #{DeathLog::DEATH_LOST_IN_TRANSIT})"
  scope :copy_lost_unpaid              , :joins => [:copy], :conditions => "(death_type_id = #{DeathLog::DEATH_LOST_BY_CUST_UNPAID})"
  scope :copy_lost_paid                , :joins => [:copy], :conditions => "(death_type_id = #{DeathLog::DEATH_SOLD})"
  scope :copy_lost_noaddr              , :joins => [:copy], :conditions => "(death_type_id = #{DeathLog::DEATH_LOST_BY_CUST_NOADDR})"
  scope :snail_warned                  , :conditions => "lawsuit_snailmail"
  scope :snail_warned_expired          , :conditions => "lawsuit_snailmail and lawsuit_snailmail < '#{Date.today + Customer::DELTA_BETWEEN_SNAIL_AND_LAWSUIT}'"
  scope :customer_good                 , :joins => [:order, :customer], :conditions => "customers.customer_id"
  scope :for_copy_in_field             , lambda { |copy|  { :conditions => "actionable and shipment_id and ISNULL(dateBack) and copy_id = #{copy.id}"}}
  scope :for_customer_and_univ         , lambda { |customer, univ |  { :joins => [:order], :conditions => "orders.customer_id = #{customer.customer_id} and orders.university_id = #{univ.andand.university_id}" } }
  scope :for_customer_and_univ_id      , lambda { |customer, univ_id |  { :joins => [:order], :conditions => "orders.customer_id = #{customer.customer_id} and orders.university_id = #{univ_id}" } }
  scope :for_order                     , lambda { |order |  { :joins => [:order], :conditions => "orders.order_id = #{order.order_id}" } }
  scope :ignore_for_univ_limits        , lambda { |cond|  { :conditions => "ignore_for_univ_limits = #{cond}"}}
  scope :in_field                      , :conditions => "shipment_id AND ISNULL(dateBack)"
  scope :late                          , :joins => [:shipment, :order], :conditions => "ISNULL(university_id) and ISNULL(dateBack) AND (TO_DAYS(dateOut) + #{DAYS_BETWEEN_SEND_AND_LATEMSG1} + overdueGraceGranted) < TO_DAYS('#{Date.today}')"
  scope :late_extra                    , lambda { |extra| { :joins => [:shipment, :order], :conditions => "ISNULL(university_id) and ISNULL(dateBack) AND (TO_DAYS(dateOut) + #{DAYS_BETWEEN_SEND_AND_LATEMSG1} + overdueGraceGranted + #{extra}) < TO_DAYS('#{Date.today}')" }}
  scope :not_back                      , :conditions => "ISNULL(dateBack)"
  scope :not_univ                      , :joins => [:order], :conditions => "ISNULL(orders.university_id)"
  scope :paid                          , :group => "line_items.line_item_id", :joins => [:order, :payments], :conditions => "complete = 1 and successful = 1"
  scope :shipped                       , :conditions => "shipment_id"
  scope :shipped_in_last_month         , :joins => [:shipment], :conditions => "TO_DAYS(DateOut) > TO_DAYS('#{Date.today << 1}')" 
  scope :shipped_since                 , lambda { |since_date| {   :joins => [:shipment], :conditions => "TO_DAYS(DateOut) >= TO_DAYS('#{since_date}')" }}
  scope :univ                          , :joins => [:order], :conditions => "orders.university_id"
  scope :unshipped_active_actionable   , :conditions => "ISNULL(shipment_id) AND line_items.live AND actionable"
  scope :unshipped_active_actionable_p , lambda { |product| {  :conditions => "product_id = #{product.product_id} AND ISNULL(shipment_id)  AND line_items.live AND actionable " }}
  scope :for_real_customer             , :joins => [:order], :conditions => "orders.customer_id > 0"
  scope :lawsuit_snailmailed           , :conditions => "lawsuit_snailmail"
  scope :lawsuit_filed                 , :conditions => "lawsuit_filed"

  #----------
  # gift card
  #----------  

  # In shipping, we need to find out if a LI needs a copy, or if it's a gift cert.
  #
  # We could find out by dragging the referenced product into memory
  # and then querying it, but this is very expensive inside the tight
  # loop of shipping calculation, so we build a cache.
  #
  @@productid_is_giftcert_cache = Array.new(Product.count, false)
  GiftCert.find(:all).each { |gc| @@productid_is_giftcert_cache[gc.product_id] = true }
  def isa_GiftCert?() @@productid_is_giftcert_cache[ product_id ] end


  #----------
  # address
  #----------  
  def us?() order.customer.shipping_address.us? end
  def canada?() order.customer.shipping_address.canada? end
  def apo?() order.customer.shipping_address.apo? end


  #----------
  # status
  #----------  
  def in_field?()    shipment_id && dateBack.nil?  end
  def pending?()     (! shipment) && actionable && live end
  def back?()        dateBack  end
  def shipped?()     shipment.to_bool end
  def returned?()    dateBack.to_bool end
  def cancelled?()   ! live  end
  

  #----------
  # utility / convenience funcs
  #----------
  def self.fix()                LineItem.connection.execute("update line_items set live = 0 where order_id = 0") end
  def canada?()                 customer.andand.shipping_address.andand.canada?  end
  def charge_type()             order.nil? ? :rental : order.charge_type     end # a bit of a hack, to deal w rogue lineitems
  def customer()                order.andand.customer  end
  def date()                    order.date  end
  def dateOrdered()             order.andand.orderDate || Date.parse("2005-01-01")  end
  def dateOut()                 shipment.andand.dateOut  end
  def gift_cert?()              product.gift_cert? end
  def late_charges()            children_lis.select { |li| li.charge_type == :late }  end
  def most_recent_late_charge() late_charges.max_by { |li| li.date }       end
  def name()                    product.andand.name end
  def paid?()                   order.andand.paid?  end
  def rental?()                 charge_type == :rental   end
  def replacement?()            charge_type == :replacement   end
  def university()              order.university end
  def lawsuit_filed!()          
    raise "already set!" unless lawsuit_filed.nil?
    update_attributes(:lawsuit_filed => DateTime.now) 
  end

     # this is a place holder until we can allow folks to sort items up and down
  def position_in_order()       
    return nil if in_field? || cancelled? || returned?
    # LineItem.for_customer_and_univ_id(order.customer,order.university_id).unshipped_active_actionable.select { |li| li.line_item_id <= line_item_id }.size 
    queue_position
  end


  # Move this line item to the top of the queue.
  # Return a list of all modified line items OTHER than this one.
  def move_to_top()
    modify = order.line_items_pending.select { |li| li.queue_position < queue_position  }
    modify.each { |li|
      li.update_attributes(:queue_position => li.queue_position + 1)
    }

    update_attributes(:queue_position => 1)
    modify
  end

  #----------
  # act on the LI
  #----------
  def univ_doesnt_countable?()  order.university && in_field? && ignore_for_univ_limits == false  end
  def univ_doesnt_count!()
    raise "not univ_doesnt_count-able" unless univ_doesnt_countable?
    update_attributes(:ignore_for_univ_limits => true)
  end
  
private
  def change_liveness(liveness)
    LineItem.transaction do
      update_attributes(:live => liveness)
      CancellationLog.create!(:new_liveness => liveness, :reference => self)
    end
  end

public
  def cancellable?(force = false)  
    # can't cancel when being shipped!
    force ||  (actionable && potential_item.nil?  && live )
  end

  def cancel(force = false)
    raise "not cancellable (force = #{force}) #{id}: #{live} // #{actionable} // #{shipment}" unless cancellable?(force)
    change_liveness(false)
    potential_item.destroy if potential_item
  end

  # we only allow customers to uncancel 
  #    * cancelled
  #    * unshipped
  #    * univ orders
  def uncancellable?()  ((! live) && shipment.nil? && order.university).to_bool  end
  def uncancel()
    raise "not uncancellable" unless uncancellable?
    change_liveness(true)
  end

  def duplicate
    LineItem.create!(:order => order, :product => product, :queue_position => 1)
  end

  
  def graceable?()  
    in_field? && 
      (copy.andand.status  == 1) &&
#      (overdueGraceGranted == 0) &&
      (charge_type != :university) 
  end

  def grace(days = 7)
    raise "not graceable" unless graceable?
    update_attributes(:overdueGraceGranted => overdueGraceGranted  + days)
  end
  
  def reshippable?()  in_field? && (copy.andand.status  == 1) end
  
  def refundable?()    true  && price > 0 end
  def refund()
    raise "not refundable" unless refundable?
    
    #       ret = ChargeEngine.refund_credit_card(order.most_recent_payment_good.credit_card,
    #                                             order.customer, 
    #                                             price, 
    #                                             "line item #{id} refunded" )
    ret = ChargeEngine.refund_customer(order.customer, 
                                       price, 
                                       "line item #{id} refunded",
                                       order.most_recent_payment_good)
    
    update_attributes(:refunded => true) if ret[0]
    ret
  end
  
  def paid?
    order.andand.paid?
  end
  
  
  def late_charge?()                   charge_type == :late   end

  #----------
  # due date, overdue, late?
  #----------
  def date_due
    dateOut + 
      DAYS_BETWEEN_SEND_AND_LATEMSG1 +
      overdueGraceGranted + 
      (canada? ? DAYS_EXTRA_FOR_CANADA : 0) + 
      (apo?    ? DAYS_EXTRA_FOR_APO : 0) 
  end

  def days_overdue
    return 0 unless ( in_field? && ( copy.andand.good? || copy.andand.lost_unpaid? || copy.andand.lost_noaddr? ))
    Date.today - date_due
  end

  def late?
      days_overdue > 0
  end
  
  def total_late_fee
    ( days_overdue / 7 ) * product.late_price
  end
  
  def dateCancelled
    # We don't store a cancelled date (we should!).
    #
    # Best we can do: assume that once an LI is cancelled, that's the
    # last update we make to it, and use the updated_at date.
    #
    # Older LIs have nil updated_at ; use the orderDate.
    updated = updated_at || dateOrdered
    ((! live) && updated.to_date).false_to_nil
  end
  
  
  #----------------------------------------
  # second-level utility funcs
  #---------------------------------------- 
  
  # potential states of a LI:
  # 
  #    :not_existing          
  #       |
  #       +-> :fee
  #       |
  #       v
  #    :not_shipped
  #       |
  #       +-> :cancelled
  #       |
  #       v
  #    :in_field
  #       |
  #       v
  #    :back
  
  def status_at(query_date = Date.today)
    query_date = Date.parse(query_date) if query_date.is_a?(String)
    return :not_existing if query_date < dateOrdered

    return :fee if charge_type == :replacement || charge_type == :late
    
    return :back if (dateBack && query_date >= dateBack)
    if (dateOut && (query_date >= dateOut) && (dateBack.nil? || dateBack >= query_date))
      return copy.andand.thought_lost? ?  :lost_in_field : :in_field
    end
    
    return :cancelled if dateCancelled && query_date >= dateCancelled
    return :not_shipped if query_date >= dateOrdered && ((dateCancelled && query_date <= dateCancelled) || 
                                                         (dateOut.nil?  || query_date <= dateOut))
    
    throw "internal error - illegal state for line_items #{self.inspect}"
  end
  
  #----------------------------------------
  # third-level utility funcs
  #---------------------------------------- 
  
  def live_at(query_date)
    ret = [:not_shipped, :in_field].include?(status_at(query_date))
    ret
  end
  
  
  
  # Handle a situation where we've sent the wrong copy; this changes the
  # line item to reflect what was actually sent, and changes the
  # in-stock / out-of-stock status of the appropriate copies.
  
  def wrong_copy_sent(actually_sent_copy)

    # Dup is required, because otherwise updating the copy pointed to by
    # the line item updates the copy in place
    thought_sent_copy = self.copy.clone
    
    if (thought_sent_copy != actually_sent_copy)
      self.update_attributes(:copy => actually_sent_copy, :intended_copy => thought_sent_copy, :wrongItemSent => true)
    else
      # *** WARNING: line item already seems to have been updated to new copy!
      return
    end
    
    # Update the in-stock status of the copy we thought we sent as in-stock
    if (!thought_sent_copy.inStock?)
      thought_sent_copy.update_attributes(:inStock => true)
    else
      # *** WARNING: copy we thought we sent is already marked as here!
    end
    
    # Update the in-stock status of the copy we actually send as not-in-stock
    if (actually_sent_copy.inStock?)
      actually_sent_copy.update_attributes(:inStock => false)
    else
      # *** WARNING: actually sent copy is already marked out!
    end
    
    return
  end
  
  
  # Create a line item for a particular product
  def self.for_product(product, price, parent_li = nil, live = true, order_id = nil)
    product_id = product.is_a?(Product) ? product.product_id : product
    LineItem.create!(:product_id => product_id, 
                     :price => price, 
                     :parent_li => parent_li,
                     :live => live,
                     :order_id => order_id)
  end
  
  def shipment_date_for_listing
    shipment.shipment_date.strftime('%a %b %d, %Y')
  rescue
    '[date-unknown]'
  end
  
  def early_arrival_date_for_listing
    self.line_item_status.early_arrival_date.strftime('%a %b %d, %Y')
  rescue
    '[date-unknown]'
  end
  
  def late_arrival_date_for_listing
    self.line_item_status.late_arrival_date.strftime('%a %b %d, %Y')
  rescue
    '[date-unknown]'
  end

  def days_delay
    position_in_queue = product.customerLocationInQueue(customer.id)
    ProductDelay.find_by_product_id_and_ordinal(product_id, position_in_queue).andand.days_delay
  end

  def wait_text
    case days_delay
    when 0 then 'within one business day'
    when 1..7 then 'within the week'
    when 9..30 then 'within the month'
    when 31..60 then 'after a long wait'
    when 60..1000 then  'after a very long wait'
    else  'unknown'
    end
  end


  # Return the text specifying the status code, with a default of the first onein the DB (pending)
  def status_text
    begin
      if back?
        return "received back"
      elsif in_field?
        return "shipped"
      elsif ! order.paid?
        return "no valid payment"
      elsif ! live
        return "cancelled"
      else
        return "pending"
      end
    rescue 
      return 'internal error'
    end
  end
  
  def where_in_list_applies
    ! (order.late? || order.replacement? || ! paid? || university)
  end

  def where_in_list
    product.customerLocationInQueue(customer.id, :ignore_univs => true )
  end

  def where_in_list_str
    return "" unless where_in_list_applies
    ret = where_in_list_and_num_copies
    if ret.nil? || ret.empty?
      return ""
    else
      return "#{ret[0]}; #{ret[1]} copies"
    end
  end

  def uni_wait_str
    position_in_queue = product.customerLocationInQueue(customer.id)
    days_delay = ProductDelay.find_by_product_id_and_ordinal(product_id, position_in_queue).andand.days_delay

    case days_delay
    when 0 then 'now'
    when 1..7 then 'short wait'
    when 9..30 then 'medium wait'
    when 31..1000 then  'long wait'
    else  'unknown'
    end

  end


  # return 2-element array
  #    [0]    - orinal
  #    [1]    - number of good copies in circulation
  def where_in_list_and_num_copies
    return [] if shipment
    [ where_in_list, product.numLiveCopies ]
  end
  
  #----------------------------------------
  # class methods
  #----------------------------------------
  
  def self.ERRORCHECK_find_orderless()
    LineItem.find(:all, 
                  :joins => "   LEFT JOIN orders ON line_items.order_id = orders.order_id",
                  :conditions => "ISNULL(orders.order_id) and line_items.live = 1")
  end
  
  def self.find_open()
    find(:all, :conditions => "live = 1 AND ISNULL(shipment_id) AND actionable = 1").select(&:paid?)
  end
  
  def self.find_open_grouped_by_order()
    LineItem.fix
    lis = LineItem.unshipped_active_actionable.includes( { :order => :payments })
    gbo = lis.group_by(&:order).select { |order, lis| order && order.paid? }
  end
  
  # Gets all line items that have shipped, have not returned, and have send 2 late msgs.
  # Does NOT select on copy status (maybe the copy is known to have gotten lost in the mail), etc.
  #
  def self.deeply_overdue
    LineItem.find(:all, :conditions =>"!ISNULL(shipment_id) AND ISNULL(dateBack) AND ! ISNULL(lateMsg2Sent)")
  end
  
  def self.late_items_by_customer_internal
    # what LIs meet the American standard for lateness?
    all_lis = LineItem.late.copy_good

    # what LIs meet the Canadian standard?
    long_duration_lis = LineItem.late_extra(DAYS_EXTRA_FOR_CANADA).copy_good

    # NOTE: we make no assertions about the nationality / shipping
    # addr of these customers!  We're just asking "what LIs meet these
    # standards ?"

    short_duration_lis = all_lis - long_duration_lis

    long_duration_lis + short_duration_lis.select { |li| li.us?}

  end

  def self.late_items_warnable
    late_items_by_customer_internal.select { |li| li.lateMsg1Sent.nil? }
  end


  def self.late_items_chargeable
    warned_lis = late_items_by_customer_internal.select { |li| li.lateMsg1Sent }

    hh = warned_lis.group_by { |li| li.most_recent_late_charge.nil? ? "just warned" : "charged already"}

    ready_to_charge = []

    first  = hh["just warned"].andand.select { |li| (li.lateMsg1Sent + DAYS_BETWEEN_LATEMSG1_AND_CHARGE) <= Date.today }
    subsequent = hh["charged already"].andand.select { |li| (li.most_recent_late_charge.date + DAYS_BETWEEN_CHARGE_AND_CHARGE) <= Date.today }

    ready_to_charge = first + subsequent
    ready_to_charge
  end

end

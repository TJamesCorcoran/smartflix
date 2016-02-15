class Campaign < ActiveRecord::Base
  self.primary_key = :id

#RAILS3  unloadable

  validates_uniqueness_of :ct_code
  validates_uniqueness_of :name

  has_many :customers, :through => :orders
  has_many :orders,    :finder_sql => 'select * from orders where orders.ct_code = "#{ct_code}"'
  has_many :origins,   :finder_sql => 'select * from origins where origins.ct_code = "#{ct_code}"'

  # just because HeavyInk has subscriptions doesn't mean that every application does!
  #
  if :SITE_NAME ==  'HeavyInk'
    has_many :subscriptions,    :finder_sql => 'select * from subscriptions where subscriptions.ct_code = "#{ct_code}"'
  end


  #----------
  # cost
  #----------

  def variable_cost
    # speed
    return 0 if origins.count == 0
    unit_cost * origins.count 
  end

  def total_cost
    fixed_cost + variable_cost
  end

  #----------
  # revenue
  #----------

  def booked_revenue()    orders.map(&:booked_revenue).sum    end
  def realized_revenue()  orders.map(&:realized_revenue).sum  end

  #----------
  # profit
  #----------

  def booked_profit()     orders.map(&:booked_profit).sum end
  def realized_profit()  orders.map(&:booked_profit).sum end

  #----------
  # profit
  #----------

  def booked_profit_after_advert()    booked_profit - total_cost  end
  def realized_profit_after_advert() realized_profit - total_cost   end

end


#class Campaign < ActiveRecord::Base
#
#  REVENUE_MULTIPLIER = 3
#
#  validates_length_of :campaign_name, :within => 4..100, :message=>"campaign length > 4, < 100 chars"
#  validates_uniqueness_of :initial_uri_regexp, :allow_nil =>true, :if => Proc.new { |camp| ! camp.initial_uri_regexp.nil? && ! camp.initial_uri_regexp.empty? }
#  validates_uniqueness_of :coupon,             :allow_nil =>true, :if => Proc.new { |camp| ! camp.coupon.nil? && ! camp.coupon.empty? }
#  validates_uniqueness_of :campaign_name
#  belongs_to :category
#
#  def name() campaign_name  end
#  def validate
#    if campaign_name.match(/what do we call/)
#      errors.add_to_base('supply a real campaign name')
#    end
#
#      
#    printP = ! (coupon.nil? || coupon.empty?)
#    onlineP = ! (initial_uri_regexp.nil? || initial_uri_regexp.empty?)
#    if ! printP &&  ! onlineP
#      errors.add_to_base('need either uri or coupon code')
#    end
#
#    if (printP && onlineP)
#      errors.add_to_base('just one of uri / coupon')
#    end
#
#    start_bound = "2005-01-01"
#    end_bound = "2015-01-01"
#    # XYZFIX P3: throws ugly error if either date isn't specified.  Needs to either be tolerant of lack, or cleanly complain.
#    if (start_date.nil? || start_date < Date.strptime(start_bound) || start_date > Date.strptime(end_bound))
#        errors.add_to_base("valid start date required between #{start_bound} and #{end_bound}")
#    end
#
#    # errors.add_to_base("start date > end date")    if end_date.nil? || end_date.nil? || start_date > end_date
#
#  end
#
#  # we need to match either the coupon code or the initial URI - don't replicate that code all over
#  def sql_regexp_stub
#    if !coupon.nil? && !coupon.empty?
#      "co.first_coupon REGEXP '#{coupon}'"
#    else
#      "co.first_uri    REGEXP '#{initial_uri_regexp}'"
#    end
#  end
#  
#  def customers
#    Customer.find_by_sql("select * from customers c, origins co where c.customer_id = co.customer_id and " + sql_regexp_stub)
#  end
#  
#  def num_customers() 
#    # TOO SLOW: customers.size
#    Customer.count_by_sql("select count(1) from customers c, origins co where c.customer_id = co.customer_id and " + sql_regexp_stub)
#  end
#
#  def actual_revenue_multiplier
#    # we trust incoming links; we don't trust coupon codes - apply a fudge factor
#    (initial_uri_regexp.nil? || initial_uri_regexp == "") ?  REVENUE_MULTIPLIER : 1
#  end
#
#  def revenue
##     Customer.find_by_sql("SELECT sum(price) as revenue 
##                           FROM line_items li, orders cord, origins co 
##                           WHERE li.live = 1 
##                           AND li.order_id = cord.order_id 
##                           AND cord.customer_id = co.customer_id
##                           AND " + sql_regexp_stub).first["revenue"].to_f
#    actual_revenue_multiplier * customers.inject(0.0) { |val, cust | val += cust.revenue}
#  end
#
#  def profit
#    cust_profit = actual_revenue_multiplier * customers.inject(0.0) { |val, cust | val += cust.profit}  
#    begin
#    cust_profit - fixed_cost.to_f - (customers.size * unit_cost)
#    rescue
#      raise "#{self.id} : #{cust_profit} - #{fixed_cost} - (#{customers.size} * #{unit_cost})"
#    end
#  end
#
#  def live_at(date)
#    start_date <= date && end_date >= date    
#  end
#end
#
#class Date 
#  def live_campaigns
#    Campaign.find(:all, :conditions =>"start_date <= '#{self.to_s}' and end_date >= '#{self.to_s}' ")
#  end
#end
#

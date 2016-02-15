require 'onepage_auth_token'
# require 'acts_as_abtest_visitor'
# require 'acts_as_notable'

require 'erb'
require 'tempfile'



class Customer < ActiveRecord::Base
  self.primary_key = "customer_id"
  attr_protected # <-- blank means total access

  
  SNAILMAIL_TEMPLATE = 'app/views/admin/customers/snailmail_template.erb'
  DELTA_BETWEEN_SNAIL_AND_LAWSUIT = 21
  
  include NewsletterEditorMixin::Customer
#  acts_as_abtest_visitor
  acts_as_notable  
  
#  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :ship_rate, :via_email_capture, :via_email_capture_details, :first_ip_addr, :first_server_name, :first_university_id, :throttleP
#  attr_accessor :password_confirmation
  
  belongs_to :shipping_address, :class_name => 'Address', :foreign_key => 'shipping_address_id'
  belongs_to :billing_address,  :class_name => 'Address', :foreign_key => 'billing_address_id'
  
  has_many :orders, :order => 'created_at DESC'
  has_many :recent_orders, :class_name => 'Order', :conditions => "server_name != 'late charge' AND server_name != 'replacement charge'", :order => 'created_at DESC', :limit => 3
  has_one :last_order, :class_name => 'Order', :conditions => "server_name != 'late charge' AND server_name != 'replacement charge'", :order => 'created_at DESC'
  has_many :payments
  has_many :good_payments, :class_name => 'Payment', :conditions => "complete = true and successful = true"
  has_many :survey_answers
  has_many :email_campaigns, :through => :campaigns_sent_to_customers
  has_many :campaigns_sent_to_customers, :foreign_key => 'customerID'
  has_many :credit_cards, :conditions => { :disabled => false }
  has_many :credit_cards_all, :class_name => 'CreditCard'
  has_many :ebay_auctions, :finder_sql => proc { 'select * from ebay_auctions where email_addr = "#{email}"'}
  has_many :origins
  has_many :ratings
  has_many :reviews, :class_name => 'Rating', :conditions => 'NOT ISNULL(review) AND approved=1'
  has_one  :abandoned_basket_email  
  
  # This doesn't seem to work, code it manually
  # has_many :line_items, :through => :orders
  has_many :line_items, :finder_sql =>  proc {"SELECT line_items.*
                                          FROM line_items, orders
                                         WHERE line_items.order_id=orders.order_id
                                           AND orders.customer_id=#{id}"}
  
  has_many :shipped_line_items, :class_name => 'LineItem', :finder_sql => proc {"SELECT line_items.*
                                                                             FROM line_items, orders
                                                                            WHERE line_items.order_id=orders.order_id
                                                                              AND NOT ISNULL(line_items.shipment_id)
                                                                              AND orders.customer_id=#{id}"}
  

  # exclude gift certificates from 
  #    line_items_shipped_not_returned
  has_many :line_items_shipped_not_returned,
  :class_name => 'LineItem',
  :finder_sql => proc {"SELECT line_items.* 
                  FROM line_items, orders, products
                 WHERE line_items.order_id=orders.order_id
                   AND line_items.product_id = products.product_id
                   AND type='Video'
                   AND shipment_id
                   AND ISNULL(dateBack)
                   AND orders.customer_id=#{id}"}
  
  has_many :uncancelled_and_actionable_line_items,
  :class_name => 'LineItem',
  :finder_sql => proc { "SELECT line_items.*
                               FROM line_items, orders
                              WHERE
                                    line_items.order_id=orders.order_id
                                AND line_items.live=1
                                AND orders.customer_id=#{id}
                                AND line_items.actionable=1"}

  has_many :uncancelled_line_items,
  :class_name => 'LineItem',
  :finder_sql => proc { "SELECT line_items.*
                               FROM line_items, orders
                              WHERE
                                    line_items.order_id=orders.order_id
                                AND line_items.live=1
                                AND orders.customer_id=#{id}"}

  has_many :uncancelled_and_actionable_and_unshipped_line_items,
  :class_name => 'LineItem',
  :finder_sql => proc { "SELECT line_items.*
                               FROM line_items, orders
                              WHERE
                                    line_items.order_id=orders.order_id
                                AND line_items.live=1
                                AND orders.customer_id=#{id}
                                AND line_items.actionable=1
                                AND ISNULL(line_items.shipment_id)
                                AND ISNULL(orders.university_id)"}
  
  has_many :uncancelled_orders,
  :class_name => 'LineItem',
  :finder_sql => proc { "SELECT orders.*
                               FROM line_items, orders
                              WHERE line_items.order_id=orders.order_id
                                AND line_items.live=1
                                AND orders.customer_id=#{id}
                              GROUP BY orders.order_id"}

  delegate :customs?, :to => :shipping_address
  
  def uncancelled_and_unshipped_line_items_payment_good
    uncancelled_and_actionable_and_unshipped_line_items.select {|li| li.order.paid?}
  end
  
  def uncancelled_and_unshipped_line_items_payment_bad
    uncancelled_and_actionable_and_unshipped_line_items.select {|li| li.order.payment_complete? && ! li.order.paid?}
  end

  def uncancelled_and_unshipped_line_items_payment_incomplete
    uncancelled_and_actionable_and_unshipped_line_items.select {|li| ! li.order.payment_complete?}
  end
  
  has_many :email_preferences
  has_many :scheduled_emails
  has_many :newsletter_recipients

  

  has_many :affiliate_transactions, :foreign_key => 'affiliate_customer_id'
  # Payments are affiliate transactions that have type P
  has_many :affiliate_payment_transactions, :class_name => 'AffiliateTransaction',
            :foreign_key => 'affiliate_customer_id',
            :conditions => "transaction_type = 'P'"

  has_many :affiliate_referral_transactions, :class_name => 'AffiliateTransaction',
            :foreign_key => 'referred_customer_id'


  has_many :recommended_products, :class_name => 'Product',
  :finder_sql => proc { "SELECT products.*
                             FROM customer_product_recommendations, products
                            WHERE customer_product_recommendations.customer_id = #{customer_id}
                              AND customer_product_recommendations.product_id = products.product_id
                         ORDER BY customer_product_recommendations.ordinal"}
  
  has_many :recommended_categories, :class_name => 'Category',
  :finder_sql => proc { "SELECT categories.*
                             FROM customer_category_recommendations, categories
                            WHERE customer_category_recommendations.customer_id = #{customer_id}
                              AND customer_category_recommendations.category_id = categories.category_id
                         ORDER BY customer_category_recommendations.ordinal"}
  
  has_many :carts
  def cart()    carts.last end
  
  has_many :potential_shipments
  has_one  :abandoned_basket_email
  has_one  :account_credit
  has_many :upsell_offers
  has_many :projects
  has_many :project_updates, :through => :projects, :source => :updates
  has_many :favorite_project_links
  has_many :favorite_projects, :through => :favorite_project_links, :source => :project
  has_many :comments
  has_many :posts, :foreign_key => "user_id", :order => 'id'
  has_many :wiki_page_versions, :order => 'id'
  has_many :wiki_pages, :through => :wiki_page_versions, :uniq => true
  
  
  validates_confirmation_of :password
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_format_of :ssn, :with => /^\d+$/, :if => lambda { |cust| !cust.ssn.nil? }   # Make sure ssn is valid if supplied, but allow nil
  # XYZ FIX P4: get these validations back in (see test/unit/customer_test.rb, line 27)
  # Right now they're out, because the new customer funnel wants to create partial customers 
  # that have no first or last name.
  # 
  #  validates_length_of :first_name, :minimum => 2  , :if => lambda { |cust| !cust.first_name.nil? }
  #  validates_length_of :last_name, :minimum => 2   , :if => lambda { |cust| !cust.last_name.nil? }
  validates_length_of :password, :minimum => 5, :if => lambda { |c| !c.password.nil? }   # Validate password length if it's not nil (nil is allowed, empty is not)
  validates_length_of :ssn, :is => 9, :if => lambda { |cust| !cust.ssn.nil? }
  validates_presence_of :email
  validates_uniqueness_of :email
  
  def validate
    errors.add_to_base("Password is required") if hashed_password.blank?
    # errors.add_to_base("Ship Rate must be between 2 and 8") if ship_rate.to_i > 8 || ship_rate.to_i < 2
  end
  
  
  
  #----------
  #  url tracker and related stuff (dvds you've browsed, etc.)
  #----------
  
  include UrlTracker
  def url_tracks() url_tracks_for_customer(self.id)  end

  def browsed_videos() 
    url_tracks.select { |ut| ut.action == "video" }.uniq_by(&:action_id).map { |ut| Product.find(ut.action_id) }
  end

  def url_track_ids_for_controller_action(controller_str, action_str) 
    ids_for_last_n_customer_actions(self, controller_str, action_str)
  end
  
  # what did we recommend ?
  def browsed_recommendations_sent
    scheduled_emails.select {|email| email.email_type == "browsed" }.map {|email| Product.find_by_product_id(email.product_id)}
  end
  
  # what should we recommend ?
  def browsed_but_not_rented_or_recoed
    # everything cust has browsed
    to_reco = url_track_ids_for_controller_action("store", "video").map {|video_id| Product.find_by_product_id(video_id)}.compact
    to_reco = to_reco.uniq.select { |product| product.pain < 20 }
    to_reco = to_reco - browsed_recommendations_sent
    to_reco
  end
  
  def toprated_but_never_rented(category)
    category.top_rated - products_ordered
  end

  def univs_by_browsed_categories
    browsed_videos.map(&:categories).flatten.uniq.map(&:universities).flatten.uniq
  end

  def univs_by_rented
    products_ordered.map(&:categories).flatten.uniq.map(&:universities).flatten.uniq
  end
  
  #----------
  #  authentication
  #----------
  
  # Given a password, generate the hashed version
  def Customer.hash_password(password, salt)
    return "#{Digest::MD5.hexdigest(salt + password)}:#{salt}"
  end
  
  
  
  # Authenticate a customer; password management is constrained to be
  # the same as used by ZenCart, since we're porting all our customers
  # over from there
  def Customer.authenticate(email, password)

    # in development mode allow XYZ to login
    #    1) w username <username> ** OR ** with customer_id
    #    2) w password DEVEL
    if (Rails.env == "development" && password == SmartFlix::Application::FAKE_DEVEL_PASSWORD)
      if email.to_i > 0
        login_customer = Customer[email.to_i]
      else
        login_customer = Customer.find_by_email(email)
      end
      return login_customer
    end


    login_customer = Customer.find_by_email(email)
    if (login_customer)
      hashed_password = Customer.hash_password(password, login_customer.salt)
      if (login_customer.hashed_password == hashed_password) 
        return login_customer
      end
    end
    return nil
  end
  
  attr_reader :password
  def password=(password)
    @password = password
    salt = rand(256).to_s(16)
    self.hashed_password = Customer.hash_password(password, salt)
  end
  
  # Get the salt (stored as part of the hashed password)
  def salt
    self.hashed_password.split(/:/)[1]
  end
  
  #----------
  #  admin
  #----------
  
  # Property defined for wiki plugin
  # see also forum_admin? in smartflix_beast/app/models/user.rb
  def wiki_editor?
    #    [210597,200937,200001].include?(self.id)
    true
  end
  def admin?
    [210597,200937,200001,258862].include?(self.id)
  end
  alias_method :projects_admin?, :admin?
  alias_method :contest_admin?,  :admin?
  alias_method :is_admin?,       :admin?
  
  
  #----------
  #  user generated content (ratings, wiki, projects)
  #----------
  
  # Determine whether the customer has reviewed a video
  def has_reviewed?(video)
    ratings.map(&:product).include?(Product.find(video))
  end
  
  
  
  
  #----------
  #  misc utility funcs
  #----------
  
  def customs?
    # protect against (historical) broken data
    shipping_address.andand.customs?
  end
  
  # Given an address ID, return the address if it is one of the
  # addresses that belongs to this user.
  def find_address(id)
    case id.to_i
    when shipping_address_id then shipping_address
    when billing_address_id then billing_address
    else nil
    end
  end
  
  # in public places: "<first name>, <last initial>"
  def display_name(options={})
    options[:period] ||= true
    
    first = first_name || shipping_address.andand.first_name || ""
    last  = last_name  || shipping_address.andand.last_name  || ""
    
    return nil if (first.empty? || last.empty?)
    first + (last.length > 0 ? " #{last[0,1]}#{'.' if options[:period]}" : '')
  end
  
  def display_name_posessive() 
    display_name && "#{display_name}'s"
  end
  
  
  def full_customer?()
    ! shipping_address.nil?
  end
  
  def name() email  end
  
  # XYZFIX P2: why chase through to the shipping addr if we have these columns present in the customer?
  def full_name()  
    if shipping_address  
      shipping_address.full_name 
    else
      "#{first_name} #{last_name}"
    end
  end
  
  def first_name() shipping_address.first_name if shipping_address  end
  
  def throttle() 
    self.throttleP = true
    save!
  end
  def unthrottle() 
    self.throttleP = false
    save!
  end
  
  
  #----------------------------------------
  # orders placed
  #----------------------------------------
  # Given an order ID, return the order if it belongs to this user
  def find_order(id)
    orders.find_by_order_id(id)
  end
  
  
  def copies
    line_items.select { |li| li.shipment }.map(&:copy).uniq
  end
  
  def products_ordered
    uncancelled_line_items.map(&:product).uniq
  end
  
  def has_rented?(video)
    orders.map(&:line_items).flatten.map(&:product).include?(Product.find(video))
  end
  
  def ever_ordered_product?(product)
    uncancelled_line_items.any? { |uli| uli.product_id == product.id }
  end
  
  def open_line_items
    line_items.select { |li| li.live == true && li.shipment.nil? && li.paid? && li.actionable }
  end
  
  def open_products
    open_line_items.map(&:product)
  end
  
  # if customer's initial URI was a product, return the product_id, else nil
  def initial_product_id
    return nil if origin.empty? || origin[0].first_uri.nil?
    uri = origins[0].first_uri
    id = case 
         when uri.match("/store/video/([0-9]+)") then $~[1].to_i
         when uri.match(Regexp.escape("/index.php?main_page=product_info&products_id=") << "([0-9]+)") then $~[1].to_i
         end
  end
  
  def initial_product 
    initial_product_id.nil? ? nil : Product.find(initial_product_id)
  end
  
  def rented_initial_product
    line_items.map{|li| li.product_id}.include?(initial_product_id)
  end
  
  def firstOrderDate()
    results = self.class.find_by_sql("SELECT MIN(orderDate) AS firstOrder FROM orders WHERE customer_id = #{self.id}")
    date = results[0].firstOrder
  end
  
  
  def first_shipment_delay
    if ( orders.size == 0 || shipments.size == 0 ) then return nil end
    
    firstOrder    = orders.map    { |o|  o.orderDate }.sort[0]
    firstShipment = shipments.map { |ss| ss.dateOut  }.sort[0]
    (firstShipment - firstOrder).to_i
  end
  
  
  #----------------------------------------
  # shipments & line-items
  #----------------------------------------
  
  # Given a line item ID, return the line item if it belongs to this user
  def find_line_item(id)
    # XXXFIX P3: Use has many through of line_items when it works...
    line_items.detect { |li| li.line_item_id == id.to_i }
  end
  
  def potential_items() potential_shipments.map(&:potential_items).flatten end
  
  def shipments
    line_items.map(&:shipment).uniq.reject{ |ship| ship.nil? }
  end
  
  # XYZFIX P3: want to exclude things that we shipped, but were defective
  def products_shipped
    shipped_line_items.map(&:product).uniq
  end
  
  def ever_shipped_product?(product)
    shipped_line_items.any? { |li| li.product_id == product.id }
  end
  
  # what DVDs are live and in the field w this customer?
  def lis_in_field
    line_items_shipped_not_returned.select{ |li| li.copy.andand.live? }
  end

  def lis_in_field_unpaid
    line_items_shipped_not_returned.select{ |li| li.copy.andand.unpaid? }
  end
  
  def lis_in_field_for_sf
    lis_in_field.select { |li| ! li.order.university }
  end
  
  def lis_in_field_for_univ(univ = nil)
    return lis_in_field_for_sf if univ.nil? 
    univ_id = univ.is_a?(University) ? univ.id : univ
    # NOTE: pass in 'false', because we want to find the ones that match the "do NOT ignore"
    LineItem.for_customer_and_univ_id(self, univ_id).in_field
  end

  # if nil is passed in, then return *all* univ dvds
  # XYZFIX P2 - test this
  def lis_in_field_for_univ_that_count(univ = nil)
    if univ_id.nil?
      LineItem.for_customer_and_univ_any(self).ignore_for_univ_limits(false).in_field.copy_good
    else
      univ_id = univ.is_a?(University) ? univ.id : univ
      # NOTE: pass in 'false', because we want to find the ones that match the "do NOT ignore"
      LineItem.for_customer_and_univ_id(self, univ_id).ignore_for_univ_limits(false).in_field.copy_good
    end
  end
  
  
  # what has been recently shipped ?
  def recently_shipped
    lis_in_field.select { |li| li.shipment &&  li.shipment.dateOut + 7 > Date.today}
  end
  

  def regular_orders()         orders.reject{|o| o.university}  end
  def univ_orders()            Order.for_cust(self).for_univ_any  end
  def univ_order_univs()       univ_orders.map(&:university)  end
  def univ_orders_that_count() univ_orders.select {|o| o.counts? }  end
  def univ_orders_that_count_x(univ_id) univ_orders.select{|o| o.university_id == univ_id }.select {|o| o.counts? } end

  # Live means 'uncancelled'.
  #
  # It does not mean 'payments up to date', 'still has items in queue', or anything else.
  #
  # A univ order can be live but not have shipped anything ever, or in a year, etc.
  #
  def univ_orders_live()
    Order.for_cust(self).for_univ_any.select{ |o| o.live}
  end
 
  def already_subscribed?(university)
    Order.for_cust(self).for_univ(university.university_id).any?
  end

  
  # Get list of all line items which have not yet been returned
  def unreturned_line_items
    self.uncancelled_and_actionable_line_items.select do |li|
      li.dateBack.nil? && li.copy && !DeathLog::NOT_CUSTOMER_FAULT_IF_NOT_RETURNED.include?(li.copy.death_type_id)
    end
  end
  
  # Get list of all unfulfilled line items
  def unfulfilled_line_items
    self.line_items.select { |li| li.shipment.nil? && li.live? }
  end
  
  # Get list of instock unfulfilled line items (we could use this
  # heuristically to assume they are not fulfilled due to preconditions)
  def in_stock_unfulfilled_line_items
    self.unfulfilled_line_items.select { |li| li.product.copy_available? }
  end
  
  # Get list of out of stock unfulfilled line items
  def out_of_stock_unfulfilled_line_items
    self.unfulfilled_line_items.select { |li| !li.product.copy_available? }
  end
  


  #----------------------------------------
  # univ orders
  #----------------------------------------

  # we really care about shipping per "payment month".
  #
  # Two funcs:
  #   * the actual  lis
  #   * just the count
  def shipped_in_last_month_for_univ(univ)
    univ_id = univ.is_a?(University) ? univ.id : univ

    orders = univ_orders_that_count_x(univ_id)
    return [] if orders.empty?
    univ_month_begin = orders.first.univ_month_begin
    LineItem.for_customer_and_univ_id(self,univ_id).shipped_since(univ_month_begin)
  end

  def shipped_in_last_month_for_univ_that_count(univ)
    shipped_in_last_month_for_univ(univ).reject {|li| li.ignore_for_univ_limits}
  end

  
  def shipped_in_last_month_for_univ_size(univ)
    univ_id = univ.is_a?(University) ? univ.id : univ

    raise "internal error: expected university_id, not univ (for speed!)" unless univ_id.is_a?(Fixnum)

    univ_month_begin = Order.orders_for_cust_univ(self, univ_id).first.univ_month_begin
    LineItem.for_customer_and_univ_id(self,univ_id).shipped_since(univ_month_begin).size

  end
  
  #----------------------------------------
  # how much we can ship to a customer
  #----------------------------------------
  
  # Get the number of SF video rentals we can send to this customer
  # now based on their ship_rate setting
  #
  def shippable_count_for_sf
    in_field_cnt = lis_in_field.select { |li| li.order.university_id.nil? }.size
    recently_shipped_cnt = recently_shipped.select { |li| li.order.university_id.nil? }.size
    [  [ship_rate - recently_shipped_cnt, 
        (ship_rate * 2) - in_field_cnt,
        ship_rate].min,
       0].max
  end
  
  # we ship univ dvds if
  #  1) you've got a univ order
  #  2) you've made a payment on that order wi the last month
  #  3) you've got shipments left for the month up to your max
  #
  #
  # NOTE: univ customers will receive defective DVDs from time to
  # time, and customer support will send new ones.  Those have to be sent
  # in an non-univ order, lest it count against the university monthly max!
  #
  # input
  #
  # returns:
  #    array - [ count, customer-visible-msg ]
  #
  def shippable_count_for_univ_int(univ, allocated_count)

    univorders = orders.select { |order| order.university == univ}
    univorders =  univorders.select { |o| o.live? }
    return [ 0, "You have no live university orders." ] unless univorders.any?

    return[ (shippable_count_for_sf - allocated_count), "not a university"] if univ.nil?
    univ_id = univ.is_a?(University) ? univ.id : univ
    
    
    # we don't ship DVDs if the CC is in the last month
    return [0, "You're eligible to have 0 DVDs shipped, because you're in the last chargable month of your credit card."] if in_last_chargeable_month?
    
    # find which univ order we're talking about
    univorders = Order.orders_for_cust_univ(self, univ_id).select(&:univ_and_counts)
    univorders = univorders.select { |o| o.live? } 
    return [0, "You're eligible to have 0 DVDs shipped, because you don't seem to have a university order."]    if univorders.empty?

    univorder = univorders.first
    return [0, "You're eligible to have 0 DVDs shipped, because you're not paid up"] unless univorder.univ_payed_up? 

    
    # find number in field now
    num_in_field = univorder.line_items_in_field_good_and_count.size
    
    # find number shipped in last month
    start  = univorder.univ_month_begin
    finish = univorder.univ_month_end
    num_shipped_in_month = univorder.lis_shipped_between_nonignored(start, finish).size
    
    # this is a bit tricky.
    #   (1) number to ship is capped by the "out at one time" rule
    #   (2) number to ship is also capped by the "mailed per month" rule

    ret =   [univorder.univ_paid_ship_rate - num_in_field, 
             univorder.univ_paid_ship_rate - num_shipped_in_month ].min

    comment = "University month runs from #{start} to #{finish}."
    comment << "Paid for a ship rate of #{univorder.univ_paid_ship_rate}, with #{num_in_field} in field, and #{num_shipped_in_month} shipped in month."
    comment << "...which gives us #{ret} shippable this month."

    # ...but if we've already allocated some, subtract those
    # 
    ret = ret - allocated_count

    comment << "We intend to ship out #{allocated_count} DVDs today, which brings it down to #{ret}." if allocated_count > 0

    # ...and never ship less than 0 (!!!)
    # 
    comment << "...and, of course, we can never go less than zero!" if ret < 0
    ret = [0, ret].max 

    [ret, comment] 

  end
  
  def shippable_count_for_univ(univ, allocated_count)
    raise "not a univ! - #{univ}" unless univ.nil? || univ.is_a?(University)
    pair = shippable_count_for_univ_int(univ, allocated_count)
    pair[0]
  end

  def dvds_remaining_for_univ(univ)
    univorders = orders.select { |order| order.university == univ}
    return 0 if univorders.empty?
    
    orders.map(&:line_items_unshipped_and_uncancelled).flatten.size
  end
  
  #----------------------------------------
  # credit cards / revenue
  #----------------------------------------

  def most_recent_cc
    credit_cards.max_by(&:updated_at).andand.updated_at
  end
  
  # Return the last credit card used by this customer, or nil if none.
  def find_last_card_used()
    self.credit_cards.sort_by{|x| x.id}.last
  end
  
  def valid_cards(with_expired = false)
    credit_cards.select { |cc| cc.any_chance_of_working?(with_expired) }
  end
  
  def next_to_expire_credit_card
    return nil if valid_cards.empty?
    valid_cards.sort_by { |cc| cc.expire_date }[0]
  end
  
  def last_to_expire_credit_card
    return nil if valid_cards.empty?
    valid_cards.sort_by { |cc| cc.expire_date }[-1]
  end
  
  def all_cc_charges_failed
    valid_ccs = credit_cards.select { |cc| ! cc.expired? }
    ! valid_ccs.detect { |cc| ! cc.last_charge_failed? }
  end

  def in_last_two_chargeable_months?
    last_to_expire_credit_card.andand.last_two_months?.to_bool
  end

  
  def in_last_chargeable_month?
    last_to_expire_credit_card.andand.last_month?.to_bool
  end
  
  def in_last_chargeable_week?(n = 1)
    last_to_expire_credit_card.andand.last_week?(n).to_bool
  end
  
  def revenue_by_type(type, refunded)

    if (type == :all)
      lis = line_items
    else
      lis = line_items.select { |li| li.charge_type == type}
    end

    if refunded == true
      lis = lis.select { |li| li.cancelled? }
    end

    lis.inject(0.0){ |sum, li| sum + li.price } 
  end
  
  def revenue
    good_payments.map(&:amount_as_new_revenue).sum.to_f
  end
  
  def profit
    costs  = revenue *  0.0219   # 2.19% credit card processing fees
    costs += payments.count * 0.49  # processing_fee_flat
    
    shipments.each { |ship| costs += ship.cost }

    
    unshipped = line_items.select { |li| (li.live) && li.shipment.nil?}
    sf_lis = unshipped.select { |li| ! li.order.university_id }
    # uni_lis = unshipped -  sf_lis

    costs += Shipment.default_cost(sf_lis.size)
    
    profit = revenue - costs
    
  end
  
  def revenue_before_ebay
    orders.select { |ord| ord.orderDate < first_ebay_coupon}.inject(0) { |sum, order| order.total_price }
  end
  
  def revenue_after_ebay
    orders.select { |ord| ord.orderDate >= first_ebay_coupon}.inject(0) { |sum, order| order.total_price }
  end
  
  #----------------------------------------
  # account credit
  #----------------------------------------
  
  
  # Shorthand for getting the amount of account credit this customer has
  def credit
    account_credit ? account_credit.amount : BigDecimal('0.0')
  end
  
  def credit_months
    account_credit ? account_credit.univ_months : 0
  end
  
  def credit_any?
    account_credit.andand.any?.to_bool
  end
  
  
  
  # Credit this customer's account credit balance, either by a specific
  # amount or by a gift certificate
  def add_account_credit(amount_or_gc, transaction_type = nil, months = 0)
    
    if (amount_or_gc.is_a?(GiftCertificate))
      gc = amount_or_gc
      amount = gc.amount.to_f
      univ_months = gc.univ_months.to_i
      return if gc.used?
    else
      gc = nil
      amount = amount_or_gc
      univ_months = months
    end
    
    Customer.transaction do
      
      # Create a new account credit if it doesn't exist yet, and add the amount
      self.account_credit ||= AccountCredit.new(:amount => 0.0, :univ_months => 0)
      
      self.account_credit.amount += amount.to_f
      self.account_credit.univ_months += univ_months
      
      # Track the transaction individually
      transaction_type ||= gc ? 'GiftCertificate' : 'CashCredit'
      
      transaction = AccountCreditTransaction.new(:amount => amount.andand.to_numeric_or_nil,
                                                 :univ_months => univ_months.to_numeric_or_nil,
                                                 :gift_certificate => gc,
                                                 :transaction_type => transaction_type)
      self.account_credit.account_credit_transactions << transaction
      
      # Save everything, setting the gift certificate to used if there is one
      if gc then gc.update_attributes(:used => true) end
      self.account_credit.save!
      self.save
    end
    
  end
  
  # Reduce this customers account credit by a specific amount,
  # optionally associated with a payment during checkout
  def subtract_account_credit(amount, payment = nil, univ_months = nil)

    # clean up inputs
    #
    amount ||= 0.0
    univ_months ||= 0

    # clean up current state
    #
     if account_credit.nil?
       self.account_credit = AccountCredit.create!(:amount => 0.0, :univ_months => 0)
     end

    raise "can't deduct #{amount.currency} from #{account_credit.amount.currency}" if account_credit.amount < amount
    raise "can't deduct #{univ_months} months from #{account_credit.univ_months} months" if account_credit.univ_months < univ_months
    
    # nothing to do
    return if amount == 0.0 && univ_months == 0
    
    # Subtract the amount
    account_credit.amount -= amount
    account_credit.univ_months -= univ_months
    
    # Track the transaction individually
    transaction = AccountCreditTransaction.new(:amount => amount * -1.0,
                                               :univ_months => univ_months * -1.0,
                                               :payment => payment,
                                               :transaction_type => payment ? 'Payment' : 'CashDebit')
    account_credit.account_credit_transactions << transaction
    
    # Note: We raise an error here on failed saves since this is used
    # during checkout; also, that's why we don't use a transaction
    
    account_credit.save!
    save!
    
  end
  
  
  #----------------------------------------
  # referrals
  #----------------------------------------
  
  def referrals
    affiliate_transactions.select { |tr| tr.transaction_type == "C"}
  end
  
  def referral_fee_owed
    affiliate_transactions.inject(0) { |total, trans| total + trans.amount }
  end
  
  # Calculate the balance credited to the affiliate program member
  def affiliate_balance
    # XXXFIX P3: Faster to do the math in the DB
    affiliate_transactions.inject(0.0) { |sum, t| sum + t.amount }
  end
  
  # Handle SSN storage; we store it encrypted, so define the accessors
  # for the unencrypted value ourselves
  def ssn=(ssn)
    @ssn = ssn
    self.encrypted_ssn = Encryptor.one_way_encrypt_string(ssn)
  end
  attr_reader :ssn
  
  
  #----------------------------------------
  # surveys
  #----------------------------------------
  
  def survey_question_history(question_id)
    history = Hash.new
    self.survey_answers.select { |sa| question_id == sa.survey_question_id }.each do |ans|
      history[ans.created_at] = ans.answer
    end
    history
  end
  
  def happiness_history
    self.survey_question_history(1) # magic number
  end
  
  
  #----------------------------------------
  # recomendation via website
  #----------------------------------------
  def videos_by_recently_rented_author(quant)
    authors = self.line_items.sort_by(&:order_id).reverse.map(&:product).map(&:author)
    unrented = authors.map(&:products).flatten.select { |v|
      v.product_set_member? ? v.product_set_ordinal == 1 : true
    } - self.line_items.map(&:product)
    by_author = unrented.group_by(&:author).select { |au,vs| vs.size > 1 }.map { |a,v| [a,v.sort_by { rand }[0,quant]] }
    by_author.sort_by { rand }.first
  end
  
  
  #----------------------------------------
  # recomendation via email
  #----------------------------------------
  
  # most recent first
  def sorted_scheduled_emails
    self.scheduled_emails.sort{|a,b| b.created_at <=> a.created_at}
  end
  
  def previouslyRecommended()
    reject_list = []
    results = self.class.find_by_sql("SELECT product_id FROM scheduled_emails WHERE customer_id=#{self.id}")
    results.each { |row| reject_list << row.product_id }
    return reject_list
  end
  
  #---------------------------------------- 
  # recomendations via post-checkout upsell
  #----------------------------------------

  # create (if necessary), save to db, and return an array of products
  # (Videos, UnivStubs, etc.)
  #
  def postcheckout_upsell_recommend(ordinal, num_recos, base_order)

    return nil if ! base_order
    # did the customer click refresh, or back?  If so, dig up historical data
    
    recos = UpsellOffer.find_all_by_customer_id_and_base_order_id_and_ordinal(self.id, base_order.id, ordinal).andand.map(&:reco)
    
    return recos if recos.size >= num_recos
    
    # What shall we recommend ?  
    # Saved cart items and recommendation items.  If that fails (say, on a first time customer)
    # add in other top-rated items in categories they've rented from.
    save_for_later_prods = []
    save_for_later_prods = cart.cart_items.select { |ci| ci.saved_for_later }.map(&:product) if cart
    
    univ_recs = base_order.line_items.map {|li| li.product.categories}.flatten.map{|cat| cat.universities}.flatten.uniq.compact
    
    recos = 
      univ_recs +
      save_for_later_prods  + 
      recommended_products + 
      base_order.line_items.map { |li| li.product.product_recommendations}.flatten.uniq 
    #      Product.other_products_in_categories(base_order.line_items.map(&:product))
    
    recos -= uncancelled_and_actionable_line_items.map(&:product)
    
    recos = recos.select { |product|      ( product.days_backorder < 30) && [nil, 1].include?(product.product_set_ordinal)     }
    
    
    # How shall we order the recos?  push recently reco-ed things to the end of the queue.
    #
    recos = recos.sort_by do |reco| 
      UpsellOffer.find_all_by_customer_id_and_reco(base_order.customer.id, reco).last.andand.created_at || 
        (Time.now - (60 * 60 * 24 * 365 * 100))
    end
    
    
    # What do we recommend today?  The first things in the reco list.  Save them to db.
    #
    recos = recos[0,num_recos]
    
    recos.each do |reco|
      UpsellOffer.create(:customer_id => self.id,
                         :reco => reco,
                         :base_order_id => base_order.id,
                         :ordinal => ordinal)
    end
    
    recos
  end
  
  
  #----------------------------------------
  # items browsed
  #----------------------------------------
  def self.customers_with_browsed_items
    
    # Return customers who have 1 or more browsed items in their
    # url_tracks history that we haven't yet bugged them about in
    # email.
    #
    # Note that there is room for improvement here: checking email
    # permissions at the same time, or figuring out which url_track
    # items we should bug them about, etc.
    #
    Customer.find_by_sql("
           SELECT c.*
           FROM customers c, url_tracks ut
           LEFT JOIN scheduled_emails se
                ON   ut.action_id   = se.product_id 
                AND  ut.customer_id = se.customer_id 
                AND  email_type = 'browsed'
                AND  controller = 'store' 
                AND action = 'video' 
           WHERE c.customer_id = ut.customer_id
           AND   ut.action = 'video'
           GROUP BY c.customer_id")
  end

  
  #----------------------------------------
  # email - permissions
  #----------------------------------------
  def send_email_of_type?(form_tag)

    preference_type = EmailPreferenceType.find_by_form_tag(form_tag)
    unless preference_type
      SfMailer.simple_message(SmartFlix::Application::EMAIL_TO_BUGS, 
                              SmartFlix::Application::EMAIL_FROM, 
                              "unknown preference type #{form_tag}",
                              "\nin models/customer.rb\n\n")
      return false
    end

    preference = self.email_preferences.find_by_email_preference_type_id(preference_type.id) 
    unless preference
      # if this preference type doesn't exist yet for this customer,
      # figure it out and save it.
      #
      # if cust has even 1 positive preference, make this positive 
      # if not, make this negative
      send = email_preferences.any?(&:send_email)
      preference = EmailPreference.create!(:customer => self, :email_preference_type => preference_type, :send_email => send)
    end

    return preference.send_email?


  end
  
  def send_recommendation_email?()    send_email_of_type?('recommended')  end
  def send_announcement_email?()    send_email_of_type?('announcements')  end
  def send_newsletter_email?()    send_email_of_type?('newsletters')  end
  
  def email_preferences_url
    return unless self.id
    token = OnepageAuthToken.create_token(self, 3, { :controller => 'customer', :action => 'email_prefs' })
    return "https://smartflix.com/customer/email_prefs?token=#{token}"
  end
  
  # Set up default email preferences for a new customer
  def setup_default_email_preferences(default_value)
    EmailPreferenceType.find(:all).each do |type|
      self.email_preferences << EmailPreference.new(:email_preference_type => type, :send_email => default_value)
    end
  end
  
  
  
  #----------------------------------------
  # small claims / lawsuit
  #----------------------------------------

  # We tried to sue the customer; snailmail bounced.
  # Anything in the field is utterly unrecoverable.
  # Don't 
  def no_addr!
    copies = line_items_shipped_not_returned.map(&:copy).select { |co| co.death_type_id == DeathLog::DEATH_LOST_BY_CUST_UNPAID }
    copies.each(&:mark_lost_noaddr)
    Customer.transaction do
      throttle
      add_note("copies (#{copies.count} of them) marked as lost_no_addr and customer throttled bc snailmail bounced", 1)
    end
    copies.count
  end

  # We filed to sue the customer
  def lawsuit_filed!
    lis = line_items_shipped_not_returned.select { |li| li.lawsuit_snailmail }
    Customer.transaction do
      lis.each(&:lawsuit_filed!)
    end
    lis
  end

  # lowest level
  #
  # return a hash: 
  #   { customer_1 -> [li_1, li_2], 
  #     customer_2 -> [li_1, li_2] }
  #
  def self.customers_w_unpaid
    copies = Copy.lost_unpaid

    # avoid bad data
    copies = copies.select { |cc| 
      li = cc.line_items_out_last 
      li.andand.order.andand.customer
    }

    copies = copies.select { |cc|
      li.lawsuit_snailmail.nil? &&   # we haven't yet mailed this person re this copy
      ! li.copy.lost_noaddr?         # we haven't already given up on this mailing addr
    }

    lost_gbc = copies.group_by { |copy|
      copy.line_items_out_last.order.customer
    }
  end

  # As above, but do some pruning - get the worst offenders (thus the
  # biggest court payoff)
  #
  # inputs:
  #   * ratio
  #       0   = give all customers
  #       0.5 = give any customers who have lost/stolen FIFTY PERCENT or more of the dvds we've shipped them 
  #       1   = give any customers who have lost/stolen ONE HUNDRED PERCENT of the dvds we've shipped them
  #    
  # return a hash: 
  #   { customer_1 -> [li_1, li_2], 
  #     customer_2 -> [li_1, li_2] }
  #
  
  # How to do this quickly:
  # 1) on front end:
  #     cand = Customer.candidates_for_smallclaims(1,2) ; cand.size
  #     cand.map { |k,v| [k.id, v.map(&:id) ]}.to_h
  #
  # 2) cut, paste to backend:
  #     txt = {... }
  #     hh = txt.map { |k,v| [Customer[k], v.map { |cid| Copy[cid] }] }.to_h ; hh.size
  #     Customer.print_snailmail_all(hh)
  def self.candidates_for_smallclaims(ratio = 0.6, shipments = 2)
    lost_gbc = customers_w_unpaid
    lost_gbc = lost_gbc.select { |k,v| v.size  >= k.shipped_line_items.size  * ratio}.to_h
    lost_gbc = lost_gbc.select { |k,v| k.shipments.size >= shipments }.to_h
    lost_gbc
  end

  def self.candidates_for_smallclaims_phase_2
    lis = LineItem.snail_warned_expired.not_back.copy_lost_unpaid
    lis.group_by(&:customer).each_pair do |cust, lis|
      copies = lis.map(&:copy)

      sum_late    = copies.sum(0){ |copy| copy.last_line_item.total_late_fee }
      sum_replace = copies.sum(0){ |copy| copy.replacement_price.nil? ? 0 : copy.replacement_price }
      
      sum_late = sum_late.round(2)
      sum_replace = sum_replace.round(2)
      sum_total = sum_late + sum_replace

      sum_late = sum_late.commify
      sum_replace = sum_replace.commify
      sum_total = sum_total.commify

      rental_date = lis.map(&:dateOut).min
      hardcopy_date = lis.map(&:lawsuit_snailmail).min

      # puts "======== #{cust.full_name} #{cust.customer_id}"
      # puts "         #{copies.size} dvds"
      # puts "         rented on #{rental_date}"
      # puts "         hardcopy letter on #{hardcopy_date}"
      # puts "         replacement fees:  $#{sum_replace}"
      # puts "         late fees:         $#{sum_late}"
      # puts "         total fees:        $#{sum_total}"
      # puts "#{cust.billing_address.to_s.gsub("^","     ")}
      # 
      # Customer #{cust.full_name} rented #{copies.size} DVDs
      # on #{rental_date} and agreed to terms and conditions. He owes
      # $#{sum_total} and has refused to pay despite repeated email
      # requests."

    end
  end


  # generate a .tex file for one customer 
  #
  def self.print_snailmail_one(customer, copies)
    sum_late    = copies.sum(0){ |copy| copy.last_line_item.total_late_fee }
    sum_replace = copies.sum(0){ |copy| copy.replacement_price.nil? ? 0 : copy.replacement_price }

    due_date  = Date.today + DELTA_BETWEEN_SNAIL_AND_LAWSUIT 

    template  = ERB.new(open(SNAILMAIL_TEMPLATE){|f| f.read })
    base_name = "/tmp/#{String.random_alphanumeric}"
    
    open("#{base_name}.tex", "w"){ |handle| handle << template.result(binding) }
    
    system("cd /tmp ; latex #{base_name}.tex")
    system("cd /tmp ; dvips #{base_name}.dvi")
    
    if (Rails.env == 'production')
      `(cd /tmp; lp -d #{BACKEND_PRINTER_NAME} #{base_name}.ps )`
    else
      `(cd /tmp; evince #{base_name}.ps)`
    end

    copies.each { |cc| cc.last_line_item.update_attributes(:lawsuit_snailmail => DateTime.now) }
  end

  # given a hash of { customer -> [ copies ] }, print all
  #
  def self.print_snailmail_all(customer_copies,count = nil)
    customers = customer_copies.keys
    customers = customers[0, count] if count
    customers.each do |customer|
      puts "======= #{customer.email}"
      copies = customer_copies[customer]
      print_snailmail_one(customer, copies)
      # DEFECTIVE -> logger.call("printed snailmail for #{customer.customer_id} - #{customer.email}") if ! logger.nil?
    end
    customers.size
  end

  def self.generate_and_print_snailmail_all(count = nil, logger = method(:puts))
    logger.call("small claims - calculation begin") 
    customer_copies = Customer.candidates_for_smallclaims
    logger.call("small claims - calculation end") if logger
    
    print_snailmail_all(customer_copies, count)
  end



  #----------------------------------------
  # STATS
  #----------------------------------------
  
  def self.STATS_num_visitors(fday, lday)
    ActiveRecord::Base.count_by_sql("SELECT count(distinct(session_id)) FROM url_tracks
                WHERE TO_DAYS(created_at) >= TO_DAYS(\"#{fday.to_s}\")
                  AND TO_DAYS(created_at) <= TO_DAYS(\"#{lday.to_s}\")")
  end
  
  def self.STATS_num_new_visitors(fday, lday)
    ActiveRecord::Base.count_by_sql("SELECT count(distinct(session_id)) FROM url_tracks
                LEFT JOIN customers
                ON        url_tracks.customer_id = customers.customer_id
                WHERE TO_DAYS(url_tracks.created_at) >= TO_DAYS(\"#{fday.to_s}\")
                  AND TO_DAYS(url_tracks.created_at) <= TO_DAYS(\"#{lday.to_s}\")
                  AND (ISNULL(url_tracks.customer_id) OR TO_DAYS(customers.created_at) <= TO_DAYS(\"#{fday.to_s}\"))")
  end
  
  private
  
  def self.STATS_num_visitors_cat(fday, lday, category_id, existing_custs_P, new_visitors_P)
    if existing_custs_P && new_visitors_P
      sql_snippet = " 1 "
    elsif existing_custs_P
      sql_snippet = " TO_DAYS(customer.railscart_created_at) <= TO_DAYS(\"#{fday.to_s}\"))"
    elsif new_visitors_P
      sql_snippet = "(ISNULL(url_tracks.customer_id) OR 
                         ( (TO_DAYS(customer.railscart_created_at) >= TO_DAYS(\"#{fday.to_s}\") ) AND
                           (TO_DAYS(customer.railscart_created_at) <= TO_DAYS(\"#{lday.to_s}\") ) ) )"
    else
      raise "error!"
    end
    
    
    ActiveRecord::Base.count_by_sql("SELECT count(distinct(session_id)) FROM url_tracks
                LEFT JOIN customers
                ON        url_tracks.customer_id = customers.customer_id,
                          categories_products,
                          categories
                WHERE TO_DAYS(created_at) >= TO_DAYS(\"#{fday.to_s}\")
                  AND TO_DAYS(created_at) <= TO_DAYS(\"#{lday.to_s}\")
                  AND controller = 'store'
                  AND action     = 'video'  
                  AND action_id  = categories_products.product_id 
                  AND categories_products.catID = categories.catID
                  AND (categories.catID = #{category_id} || categories.parentCatID = #{category_id} )
                  AND #{sql_snippet}")
  end
  
  public
  
  def self.STATS_num_new_visitors_cat(fday, lday, category_id)
    STATS_num_visitors_cat(fday, lday, category_id, false, true)
  end
  
  def self.STATS_num_all_visitors_cat(fday, lday, category_id)
    STATS_num_visitors_cat(fday, lday, category_id, true, true)
  end
  
  
  
  
  def self.STATS_num_new_customers(fday, lday)
    ActiveRecord::Base.count_by_sql("SELECT COUNT(1) FROM customers
                WHERE TO_DAYS(created_at) >= TO_DAYS(\"#{fday.to_s}\")
                  AND TO_DAYS(created_at) <= TO_DAYS(\"#{lday.to_s}\")")
  end
  
  def self.STATS_num_new_customers_email_capture_yes(fday, lday)
    ActiveRecord::Base.count_by_sql("SELECT COUNT(1) FROM customers
                WHERE arrived_via_email_capture = 1
                  AND TO_DAYS(created_at) >= TO_DAYS(\"#{fday.to_s}\")
                  AND TO_DAYS(created_at) <= TO_DAYS(\"#{lday.to_s}\")")
  end
  
  def self.STATS_num_new_customers_email_capture_no(fday, lday)
    ActiveRecord::Base.count_by_sql("SELECT COUNT(1) FROM customers
                WHERE arrived_via_email_capture = 0
                  AND TO_DAYS(created_at) >= TO_DAYS(\"#{fday.to_s}\")
                  AND TO_DAYS(created_at) <= TO_DAYS(\"#{lday.to_s}\")")
  end
  
  def self.STATS_num_first_orders(fday, lday)
    ActiveRecord::Base.count_by_sql("
                SELECT COUNT(1) FROM customers
                WHERE first_order_date >= \"#{fday.to_s}\"
                  AND first_order_date <= \"#{lday.to_s}\"")
  end
  
  def self.STATS_num_orders_university(fday, lday)
    ActiveRecord::Base.count_by_sql("
                SELECT COUNT(1) FROM customers, orders
                WHERE customers.customer_id = orders.customer_id
                  AND NOT ISNULL(orders.university_id)
                  AND first_order_date >= \"#{fday.to_s}\"
                  AND first_order_date <= \"#{lday.to_s}\"")
  end
  
  def self.STATS_num_full_customers(fday, lday, via_email_capture = nil)
    email_capture_sql = { nil   => "1", 
      true  => "arrived_via_email_capture = 1",      
      false => "arrived_via_email_capture = 0"}[via_email_capture]
    ActiveRecord::Base.count_by_sql("
                SELECT COUNT(1) FROM customers
                WHERE date_full_customer >= \"#{fday.to_s}\"
                  AND date_full_customer <= \"#{lday.to_s}\"
                  AND #{email_capture_sql}")
  end
  
  #----------------------------------------
  # Datamining
  #----------------------------------------
  
  def self.DATAMINE_find_delay_value_correl()
    StatArray.DATAMINE(:conn => Customer.connection,
                       :sql =>
                       "SELECT TO_DAYS(dateOut) - TO_DAYS(orderDate) as 'delay', SUM(price) as 'value'
                        FROM customers, line_items, orders,shipment
                        WHERE line_items.live = 1
                        AND customers.customer_id = orders.customer_id
                        AND  orders.order_id = line_items.order_id
                        AND line_items.shipment_id = shipment.shipment_id
                        GROUP BY customers.customer_id")
  end
  
  def self.DATAMINE_find_delay_value_correl()
    StatArray.DATAMINE(:conn => Customer.connection,
                       :sql =>
                       "SELECT TO_DAYS(dateOut) - TO_DAYS(orderDate) as 'delay', SUM(price) as 'value'
                        FROM customers, line_items, orders,shipment
                        WHERE line_items.live = 1
                        AND customers.customer_id = orders.customer_id
                        AND  orders.order_id = line_items.order_id
                        AND line_items.shipment_id = shipment.shipment_id
                        GROUP BY customers.customer_id")
  end
  
  def self.DATAMINE_find_best_search_terms()
    StatArray.FIND_HIGHEST(:ruby => lambda {
                             ret = Array.new
                             Customer.find(:all, :limit => 500, :conditions => "customer_id > 201889" ).each do |cc|
                               ret << [ (cc.origins.nil? ? nil : cc.origins[0].google_search_term),
                                        cc.lifetime_value]
                             end
                             ret
                           } )
  end
  
  # of those customers who entered the site via a product page, what percent rented ANYTHING
  def self.DATAMINE_initial_product_fraction_rented_anything
    entered_via_product = Customer.find(:all).select { |cust| !cust.initial_product_id.nil?}
    entered_via_product.select { |cust| ! cust.line_items.empty?}.size.to_f / entered_via_product.size
  end
  
  # of those customers who entered the site via a product page, what percent rented THAT product
  def self.DATAMINE_initial_product_fraction_rented_initial_product
    entered_via_product = Customer.find(:all).select { |cust| !cust.initial_product_id.nil?}
    entered_via_product.select { |cust| cust.rented_initial_product}.size.to_f / entered_via_product.size
  end
  
  
  # of those customers who entered the site NOT via a product page, what percent rented ANYTHING
  def self.DATAMINE_not_initial_product_fraction_rented_anything
    entered_via_not_product = Customer.find(:all).select { |cust| cust.initial_product_id.nil?}
    entered_via_not_product.select { |cust| ! cust.line_items.empty?}.size.to_f / entered_via_not_product.size
  end
  
  
  # what percent of customers arrive on a product page ?
  def self.DATAMINE_percent_arrive_on_product_page
    puts Customer.connection.select_all("SELECT num_on_product_page / num_customers as 'percent'
                                    FROM (SELECT count(1) as num_on_product_page 
                                          FROM customers c, customer_origins co 
                                          WHERE c.customer_id = co.customer_id 
                                          AND !ISNULL(first_uri) 
                                          AND (first_uri like '%index.php?main_page=product_info%' OR 
                                               first_uri like '%store/video%')) xxx,
                                         (SELECT count(1) as num_customers 
                                          FROM customers c, customer_origins co 
                                          WHERE c.customer_id = co.customer_id 
                                          AND !ISNULL(first_uri)) yyy")[0]["percent"].to_f
  end
  
  def self.from_site(url_fragment)
    origins = Origin.find(:all, :conditions => "referer like '%#{url_fragment}%'")
    origins.map(&:customer)
  end
  
  def referers
    origins.map(&:referer)
  end
  
  def referer_domains
    referers.select { |ref| ref }.map { |url| url.match(/(http:\/\/[^\/]*)\//) ; $1}.uniq
  end
  
  def first_ebay_coupon
    return nil if ebay_auctions.empty?
    ebay_auctions.sort_by { |auction| auction.coupon_issue_date }[0].coupon_issue_date
  end
  
  
  #----------
  #  bulk emails
  #----------
  
  
  #----------
  #  TESTING
  #----------
  
  if Rails.env != "production"
    def self.test_customer
      ship = Address.test_shipping_addr
      bill = Address.test_billing_addr
      ship.save!
      bill.save!
      Customer.new(:password => "foobar",
                   :password_confirmation => "foobar",
                   :email => 'foo@smartflix.com',
                   :first_name => 'A',
                   :last_name => 'A',
                   :shipping_address => ship,
                   :billing_address => bill,
                   :railscart_created_at => Time.now)
    end
  end
  
  #----------
  #  DATAMINING
  #----------
  
  def self.ebay_profit
    # cost: sum of the amount of money spent on each $5-cost-of-rental DVD
    cost = EbayAuction.find(:all).inject(0) { |sum, coup| sum + (5 - coup.amount_paid) }
    
    # find those customers who came to us via ebay links
    customers = Customer.from_site("ebay")     
    
    # find those customers who used an ebay coupon...but reject those
    # that did business with us BEFORE they first purchased a coupon
    # (we prevent existing customers from USING coupons, but we still
    # don't want to consider the revenue from an existing customer as
    # evidence of the success of the ebay program!)
    customers += EbayAuction.find(:all).map(&:customers).flatten.reject { |cust| cust.revenue_before_ebay > 0}  
    
    # take all these customers and sum their profits
    customers.uniq.inject(0){ |sum,cust| sum+cust.profit} - cost
  end
  
  def self.ebay_profit_per_run
    num_runs = EbayAuction.connection.select_all("SELECT count(1) as 'cnt'
                                                     FROM (
                                                     SELECT auction_date 
                                                     FROM ebay_auctions 
                                                     WHERE auction_date != '2007-09-23'
                                                     GROUP BY auction_date) zzz;")[0]["cnt"].to_i
    Customer.ebay_profit.to_f / num_runs
  end
  
  # returns a hash: 
  #   after 1 order, on average customers do $x more business with us
  #   after 2 orders, on average customers do $x more business with us
  #   etc.
  def self.DATAMINE_average_value_after_n_orders(customers)
    upper = 30  # max number of orders we'll look at
    size = customers.size
    # find the total value in everyone's first orders, their second orders, etc.
    total_value_in_nth = [] 
    0.upto(upper) do |n|
      total_value_in_nth[n] = customers.sum {   |cust|  cust.orders[n].andand.total_rental_price.to_f }
    end
    
    # now find the total value ** after ** the nth order
    total_value_inandafter_nth = []
    (upper).downto(0) do |n|
      total_value_inandafter_nth[n] = total_value_in_nth[n ].to_f + total_value_inandafter_nth[n + 1].to_f
    end
    total_value_inandafter_nth.map { |i| i/size}
  end
  
  #   def self.customers_with_overdue_charges(quant = 200)
  #     custs = Customer.find(:all).select {|cust| cust.orders.detect{|order| order.server_name == "overdue charge"} }[0, quant - 1]
  #     average_value_after_n_orders(custs)
  #   end
  
  def self.DATAMINE_customers_with_overdue_charges_at_order_x(quant = 200, x = 1)
    custs = Customer.find(:all).select {|cust| cust.orders.size >= (x + 1) && cust.orders[x].server_name == "overdue charge"}[0, quant - 1]
    DATAMINE_average_value_after_n_orders(custs)
  end
  
  def self.DATAMINE_customers_without_overdue_charges_and_had_x_orders(quant = 200, x = 1)
    custs = Customer.find(:all).select {|cust| cust.orders.size >= (x + 1) && ! cust.orders.detect{|order| order.server_name == "overdue charge"} }[0, quant - 1]
    DATAMINE_average_value_after_n_orders(custs)
  end
  
  def self.DATAMINE_compare_revenue_after_overdue_charge
    1.upto(20) do |index|
      puts "if overdue charge occurs at #{index}, then value after charge"
      begin
        good_cust_val = Customer.DATAMINE_customers_without_overdue_charges_and_had_x_orders(200, index)[index + 1]
        bad_cust_val  = Customer.DATAMINE_customers_with_overdue_charges_at_order_x(200,index)[index + 1]        
        
        puts "   regular      custs = #{good_cust_val.to_i}"
        puts "   late-charged custs = #{bad_cust_val.nan? ? "nan" : bad_cust_val.to_i}"
      rescue
        puts "   *** error caught"
      end
    end
  end
  
  def self.DATAMINE_num_items_in_wishlist
    sql_ret = Customer.connection.select_all("
          SELECT items, count(1) as instances 
          FROM (SELECT customer_id, c.cart_id, count(IF(ci.saved_for_later=1,1,NULL)) as items
                FROM (SELECT * from carts where ! ISNULL(customer_id)) c 
                LEFT JOIN cart_items ci 
                ON c.cart_id = ci.cart_id 
                GROUP BY c.cart_id ) zzz
          GROUP BY items")
    
    # we want a result array that has continuous data from first to
    # last (no skipped indices which would foul up later post-processing)
    max_index = sql_ret.last["items"].to_i
    ret = Array.new(max_index + 5){ 0 }
    #    raise "#{max_index}, #{ret.inspect}"
    sql_ret.each do |row|
      ret[row["items"].to_i] = row["instances"].to_i
    end
    ret
  end
  
  # Find items that a customer has both wishlisted ** AND ** rented.
  #
  #    SELECT line_item_id as 'li.id', product_id as 'li.product', cart_item_id as 'ca.id', product_id as 'ca.product' 
  #    FROM carts ca, cart_items ci, orders co, line_items li 
  #    WHERE ! ISNULL(ca.customer_id) 
  #    AND ca.cart_id = ci.cart_id 
  #    AND ca.customer_id = co.customer_id 
  #    AND co.order_id = li.order_id 
  #    AND ci.product_id = li.product_id;                                                                                                    
  
  # how many items on wishlist
  #  
  #  select count(1)  from carts ca, cart_items ci, orders co, line_items li where ! ISNULL(ca.customer_id) and ca.cart_id = ci.cart_id and ca.customer_id = co.customer_id and co.order_id = li.order_id and ci.product_id = li.product_id;
  
  def self.DATAMINE_num_unordered_items_in_wishlist
    sql_ret = Customer.connection.select_all("
          SELECT items, count(1) as instances 
          FROM (SELECT customer_id, c.cart_id, count(IF(ci.saved_for_later=1,1,NULL)) as items
                FROM (SELECT * from carts where ! ISNULL(customer_id)) c 
                LEFT JOIN cart_items ci 
                ON c.cart_id = ci.cart_id 
                GROUP BY c.cart_id ) zzz
          GROUP BY items")
    
    # we want a result array that has continuous data from first to
    # last (no skipped indices which would foul up later post-processing)
    max_index = sql_ret.last["items"].to_i
    ret = Array.new(max_index + 5){ 0 }
    sql_ret.each do |row|
      ret[row["items"].to_i] = row["instances"].to_i
    end
    ret
  end
  
  def self.DATAMINE_num_items_in_wishlist_grp_by_fives
    input = self.DATAMINE_num_items_in_wishlist
    #   raise input.inspect
    ret = Hash.new(0)
    input.each_with_index do |val, index| 
      hashkey = (index.to_f / 5).floor * 5
      hashkey = "#{hashkey} - #{hashkey + 4}"
      ret[hashkey] += val
    end
    ret
  end

  def self.xyz()    Customer[200001]  end

  # a research / early warning system: are there customers with insane numbers of DVDs?
  #
  def self.customers_with_tons_of_dvds
    LineItem.in_field.copy_good.group_by(&:customer).select { |cust, lis| lis.size > 10 }.to_hash
  end

end

require 'date'
class Date
  # want to use a has_many / finder_sql bit here, but that only works if Date inherits from ActiveRecord ...and it doesn't
  
  def customers_this_day
    Customer.find_by_sql("SELECT * FROM customers c  WHERE first_order_date = '#{self.to_s}'")
  end
  
  def customers_this_month
    Customer.find_by_sql("SELECT * FROM customers c  WHERE first_order_date >= '#{self.beginning_of_month}' and first_order_date <= '#{self.end_of_month}'")
  end
  
  def self.customers_between(before, after)
    Customer.find_by_sql("SELECT * FROM customers c  WHERE TO_DAYS(railscart_created_at) >= TO_DAYS('#{before}') AND TO_DAYS(railscart_created_at) <= TO_DAYS('#{after}')")
  end
  
  
  
end


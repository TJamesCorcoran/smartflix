class Array

  def to_hash
    hh = Hash.new
    self.each do |ii|
      hh[ii[0]] = ii[1]
    end
    hh
  end
end


class Product < ActiveRecord::Base
  self.primary_key = "product_id"

  attr_protected # <-- blank means total access

  include BackorderTest

  belongs_to :author
  belongs_to :vendor
#  has_many   :adwords_ads, :as => :thing_advertised
  has_many   :cart_items
  has_many   :copies, :finder_sql => proc { "select * from copies where product_id = #{product_id} and mediaformat = 2" }
  has_many   :good_copies, :class_name => 'Copy', :finder_sql => proc { "select * from copies where product_id = #{product_id} and mediaformat = 2 and status = 1" }
  has_many   :good_instock_copies, :class_name => 'Copy', :finder_sql =>proc { "select * from copies where product_id = #{product_id} and mediaformat = 2 and status = 1 and inStock = 1"}
  has_many   :line_items
  has_many   :product_bundle_memberships
  has_many   :product_bundles, :through => :product_bundle_memberships
  has_many   :product_delays
  has_many   :ratings, :conditions => 'approved = 1'
  has_many   :reviews, :class_name => 'Rating', :conditions => 'NOT ISNULL(review)'
  has_many   :universities, :through => :university_curriculum_elements
  has_many   :university_curriculum_elements, :foreign_key => :video_id
  has_many   :vendor_order_logs
  has_one    :inventory_ordered
  has_one    :product_set, :through => :product_set_membership
  has_one    :product_set_membership
  has_one    :tobuy
  MAX_PRODUCT_RECOMMENDATIONS = 5

  has_many :product_recommendations, :class_name => 'Product',
  :finder_sql => proc { "SELECT products.*
                             FROM product_recommendations, products
                            WHERE product_recommendations.product_id = #{self.product_id}
                              AND product_recommendations.recommended_product_id = products.product_id
                              AND products.display = 1
                         ORDER BY product_recommendations.ordinal
                            LIMIT #{MAX_PRODUCT_RECOMMENDATIONS}" }



  has_and_belongs_to_many :categories

  validates_uniqueness_of :name, :message => "is a duplicate"
  validates_length_of :name, :within => 4..100, :message=>"product length > 4, < 100 chars"
  validates_numericality_of :price
  validates_numericality_of :purchase_price

  delegate :hostile?,  :to => :vendor

  #----------
  # misc utility 
  #----------

  def smart_display?
    display && copies.any?
  end

  def short_name(max_len)
    ret = "#{name}"
    ret += "by #{author.name}" if author.name != "various"
    return ret if ret.size < max_len

    ret = "#{name}" 
    return ret if ret.size < max_len

    name.truncate_at_word_for_charcount(max_len)
  end

  def duplicate_of_other_product(good_product)
    Product.transaction do
      copies.each      { |co| co.update_attributes(:product_id => good_product.product_id) }
      line_items.each  { |li| li.update_attributes(:product_id => good_product.product_id) }
      cart_items.each  { |ci| ci.update_attributes(:product_id => good_product.product_id) }
      universities.each{ |u|  u.remove_product(self) }
      self.tobuy.andand.destroy
      self.destroy
    end
  end

  def create_copy
    Copy.create!(:birthDATE=>Date.today, :product_id => self.product_id)
  end

  def candidate_for_university?(univ)
    ( categories.include?(univ.category) && ! univ.products.include?(self) ).to_bool
  end

  def customers
    line_items.map { |li| li.order.customer }.uniq
  end

  def associated_universities
    categories.map(&:universities).flatten.uniq
  end

  #----------
  # ratings 
  #----------

  def avg_rating
    ratings.select {|r| r.approved }.map(&:rating).average.nan_as_nil
  end

  def ratings_n_star(n)
    ratings.select{ |rating| rating.rating >= n && 
                             rating.review.nil?.not &&
                             rating.approved }.reverse
  end

  def reviews_n_star(n)
    ratings_n_star(n).select{ |rating| rating.review}
  end

  def ratings_five_star
    ratings_n_star(5)
  end

  def rating_by_customer(customer)
    customer_id = customer.is_a?(Customer) ? customer.customer_id : customer
    Rating.find_by_product_id_and_customer_id(id, customer_id)
end

  #----------
  # prices 
  #----------
  
  def rental_price() price  end

  # for purposes of putting in boxes, etc., DVDs have "values".  Each value is either 1 or 2.
  def value 
    price <= 10 ? 1 : 2
  end

  def premium?
    value == 2
  end

  def replacement_price()
    purchase_price + 15 # $10 shipping + $5 restocking fee
  end

  LATE_WEEKLY_BASE = 4.99
  def late_price
    return(LATE_WEEKLY_BASE)  if  purchase_price.nil? || purchase_price < 70
    return(LATE_WEEKLY_BASE + 2)  if purchase_price < 120
    return(LATE_WEEKLY_BASE + 4)
  end
  
  # 99.9% of our titles have purchase price info on them...but one could always slip through.
  # We don't want to show comparison prices of $0.00 for purchasing and $9.99 for renting!
  def nonzero_purchase_price
    (  (purchase_price.nil? || purchase_price < 10.0 ) ? 40.0 : purchase_price).round(2)
  end
  
  def comparison_purchase_price
    product_set_member? ? product_sets.first.products.inject(0.0){ |sum, product| sum + product.nonzero_purchase_price}.round(2) : nonzero_purchase_price.round(2)
  end

  def comparison_rental_price
    if product_set_member? 
      cart_items = product_sets.first.products.map { |prod| CartItem.for_product(prod) }
      CartGroup.groups_for_items(cart_items).first.total.to_f.round(2) # cartgroup gives us rental price
    else
      price # that is, rental price
    end
  end
  
  def comparison_savings
    (comparison_purchase_price - comparison_rental_price).round(2)
  end
  
  def comparison_savings_percent
     (100 * (comparison_purchase_price - comparison_rental_price) / comparison_purchase_price ).to_i
  end

  #----------
  # bundles 
  #----------


  # See if this product is a member of a bundle
  def product_bundle_member?
    self.product_bundles.any?
  end



  #----------
  # line_items
  #----------

  def unshipped_lis
    # note re:
    #    .for_real_customer()
    # at end:
    #
    # For some reason we've got in our data orders with no customers
    # associated.  We don't ship these (of course!) but we also don't
    # want to consider them when we're looking at delays.
    #
    LineItem.unshipped_active_actionable_p(self).for_real_customer
  end

  def unshipped_lis_sf
    LineItem.unshipped_active_actionable_p(self).for_real_customer.not_univ
  end

  def unshipped_lis_uni
    LineItem.unshipped_active_actionable_p(self).for_real_customer.univ
  end

  #----------
  # active record stuff 
  #----------

  def validate()
    if (self[:type] != 'GiftCert' && categories.size <= 0)
      errors.add(:categories, "must have 1 or more" )
    end
  end

  def before_save()
    # to support the invariant that I hereby declare: all products shall have 'io's
    if (self.inventory_ordered.nil?)
      self.inventory_ordered = InventoryOrdered.create!(:product_id => self, :quant_dvd => 0)
    end
  end


  #----------
  # inventory
  #----------

  def quant_ordered()  self.inventory_ordered.andand.quant_dvd || 0  end


  # Determine what action to use to display this product; we simply use
  # the class name in lowercase
  def action
    self.is_a?(UnivStub) ? "video" : self.class.to_s.downcase
  end

  
  # XYZ FIX P2 - this should be moved down to the derived classes GiftCert and Video
  def gift_cert?() 
    (virtual && name.match(/Gift Cert/)).to_bool   
  end


  
  # Get the author name, this is mainly for use by ferret
  def author_name
    author.name
  rescue
    nil
  end

  # Get the primary category
  # XXXFIX P3: Eventually each category should have an assigned primary category
  def primary_category()
    return self.categories[0]
  end


  #----------
  # sets
  #----------

  def first_in_set?() product_set_ordinal == 1  end
  def first_in_set_or_standalone() product_set_ordinal.nil? || product_set_ordinal == 1  end

  def get_first_in_set_or_standalone()
    return university.products.first if self.is_a?(UnivStub)
    return self if product_set_ordinal.nil? 
    return product_set.first_product
  end

  # Get the product_set that this product is a member of
  def product_set
    product_sets[0]
  end

  # XXXFIX P3: If / when rails supports has_one :through, use that to supply product_set
  has_one :product_set_membership
  has_many :product_sets, :through => :product_set_membership
  # Is this product a member of a set?
  def product_set_member?
    # Note: We cache this here, since AR doesn't seem to cache nil and
    # always does a DB query, this may be fixed in rails 1.2
    if !defined?(@product_set_member_p_use_cache)
      @product_set_member_p_cache = !product_set_membership.nil?
      @product_set_member_p_use_cache = true
    end
    return @product_set_member_p_cache
  end


  #----------
  # preconditions
  #----------


  # Note: the purpose of this is as a speed optimization in the shipping code ; 
  #   see Shipping.prune_preconded_items.  Note that these can return false positives, 
  #   but that's OK - we just want to get the true negatives so that we can optimize
  #
  # XYZFIX P3: need to use the productDependence table here for the 10 hand-hacks I put in
  def any_preconds?()    product_set.to_bool  end
  def any_postconds?()    product_set.to_bool  end
  
  def precond
    # XYZFIX P3: need to use the productDependence table here for the 10 hand-hacks I put in
    ret = nil
    if product_set && product_set.andand.order_matters && product_set_membership.andand.ordinal > 1
      product_set.products[product_set_membership.ordinal - 2]
    else
      nil
    end
  end

  #----------
  # vendor order logs / inventory_ordered
  #    ... what have we ordered?
  #----------

  def num_copies_on_order
    inventory_ordered.andand.quant_dvd || 0
  end

  #----------
  # copies / delays
  #----------

  CYCLE_TIME = 21
  VENDOR_ORDER_DELAY_FRIENDLY = 5
  VENDOR_ORDER_DELAY_HOSTILE  = 15 
  PAIN_THRESHOLD = 10

  #:::::
  #  low-level status
  #:::::

  # Is this product available (ie in stock and not damaged)?
  def copy_available?
    num_live_copies_instock > 0
  end

  # total live DVDs
  def numLiveCopies()
    self.class.count_by_sql("SELECT COUNT(*) AS copies FROM copies
                             WHERE status = 1 AND mediaFormat = 2 AND product_id = #{self.id}")
  end

  def num_live_copies_instock
    self.class.count_by_sql("SELECT COUNT(*) AS copies FROM copies
                             WHERE status = 1 AND mediaFormat = 2 AND product_id = #{self.id} AND inStock = 1")
  end

  def self.num_live_copies_instock_array(prod_ids)
    connection.select_all("SELECT product_id, 
                                  COUNT(*) AS cnt FROM copies
                            WHERE status = 1 
                              AND mediaFormat = 2 
                              AND product_id in (#{prod_ids.join(',')}) 
                              AND inStock = 1 group by product_id").map {|h| [ h["product_id"].to_i, h["cnt"].to_i ] }.to_h
  end


  #
  # Where in line a customer (described by ID) is to get this product
  #
  def customerLocationInQueue(customer_id, options = {} )

    options.allowed_and_required([:ignore_univs], [])

    return -1 if (customer_id.nil?)

    # first we have to find out the date and the line_items ID of the
    # customer's actual order.

    lis = LineItem.find(:all,
                       :joins => "left join orders on line_items.order_id = orders.order_id",
                       :conditions =>"line_items.order_id = orders.order_id
                                     AND ISNULL(shipment_id)
                                     AND line_items.live = 1
                                     AND actionable = 1
                                     AND product_id = #{self.id}
                                     AND customer_id = #{customer_id}")


    return nil if (lis.size == 0)    
    li = lis.first

    # once we have the date and lineitem ID of the customer's order we can
    # find what his ranking in the queue is

    ignore_univ_text = ""
    ignore_univ_text = "and ISNULL(orders.university_id)" if options[:ignore_univs]

    loc = self.class.count_by_sql("SELECT count(1) as locationInList
                                     FROM line_items, orders
                                    WHERE product_id = #{self.id}
                                      AND line_items.order_id = orders.order_id
                                      AND actionable = 1
                                      AND isnull(shipment_id)
                                      AND line_items.live = 1
                                      #{ignore_univ_text}
                                      AND (orderDate < '#{li.orderDate}' OR
                                          (orderDate = '#{li.orderDate}' AND line_item_id < #{li.line_item_id}))")
    return loc.to_i

  end
  
  private

  # total live DVDs ... assuming that anything that's very overdue is dead to us
  def numLiveCopies_noting_very_late
    copies.select {|cc|  cc.mediaformat == 2 && cc.due_back.class == Fixnum }.size
  end

  #     total live DVDs
  #   - very overdue
  #   + on order
  #   -------------
  #     this
  public

  def num_circulating_copies
    numLiveCopies_noting_very_late + quant_ordered
  end

  private

  #:::::
  #  do raw calculations - compute intensive, not to be done all the time!
  #:::::

  def lis_for_delay_calculation

    # XYZFIX P3 : 
    # it'd be nice to include some fraction of the uni lis here, but let's just speed it up for now
    unshipped_lis_sf
  end

  #:::::
  #  time-based simulation - ALL OF THIS SHOULD ONLY BE CALLED IN ORDER TO CACHE RESULTS
  #:::::

  public 

  # build an array containing the arrivalDelay from today, in days, of
  # each copy arriving
  def copies_arrive()
    before = Time.now
    purchase_delay = (self.vendor.andand.vendor_mood.andand.moodText == "hostile") ? VENDOR_ORDER_DELAY_HOSTILE : VENDOR_ORDER_DELAY_FRIENDLY
    copies_arrive = []

    # build an array of arrival delays of copies we already own (0 for instock, etc.)
    #
    copies = Copy.find(:all, :conditions => "status = 1 and product_id = #{self.product_id}", :include => :line_items)
    copies.each { |cc| copies_arrive.push(cc.due_back()) }

    # ...then add to that array the arrival delays of copies we've purchased
    #
    vendor_orders_considered = 0
    vendor_orders_total = quant_ordered
    self.vendor_order_logs.reject{|x| x.quant < 0}.sort{ |a,b| b.orderDate <=> a.orderDate}.each do |vol|
      break if (vendor_orders_considered >= vendor_orders_total)
      arrivalDelay = vol.orderDate + purchase_delay - Date.today()
      # what do we do for things that should have already arrived?
      # we could say "if they're not here today, assume it's going to take another week".
      # ...BUT there is a problem w that: depending on what we set our pain threshold at,
      # that extra week could cause us to conclude "hey, it's quicker to just order new copies
      # than to wait for the ones we already ordered...so order some more!".
      # This would be THE WRONG THING.
      # Thus:  1) CODE: set the expected arrival time of overdue items as "today"
      #        2) PROCESS: be vigilant of overdue shipments (Suz and
      #           XYZ get daily emails).  Read these emails, and make
      #           sure to kill off orders that aren't being filled by
      #           vendors, etc.  Then The Right Thing will happen.
      if (arrivalDelay < 0) then arrivalDelay = 0 end
      vol.quant.times do
        copies_arrive.push(arrivalDelay)
      end
      vendor_orders_considered += vol.quant
    end
    copies_arrive = copies_arrive.reject{|x| nil == x}.sort
    copies_arrive
  end

  #  Imagine a sequence of orders being placed for this product.
  #  
  #  For the first order,  how many days till we can ship it?
  #  For the second order, how many days till we can ship it?
  #  For the third order,  how many days till we can ship it?
  #  etc.
  # 
  #  Express the answer in an array, e.g.
  #
  #     [0, 4, 20, 21, 25, 41, 42, 46, 62, 63, 67, 83, 84, 88, 104]
  #
  #  Indicating that
  #     * 1st order goes out in 0  days
  #     * 2nd order goes out in 4  days
  #     * 3rd order goes out in 20 days
  #   etc.
  #
  EXTRA_QUEUE_PLACES = 10
  def get_delay_queue
    before = Time.now
    copies_arrive_queue = copies_arrive()

    return Array.new(100, 1000) if copies_arrive_queue.empty?


    # how many LIs already exist that need delays calculated (ignore all sorts of LIs that don't qualify)
    count = lis_for_delay_calculation.size
    # ...and figure out how much the next 10 customers who get this will be delayed as well
    count += EXTRA_QUEUE_PLACES
    delay_queue = []
    count.times do | xx |
      arriveDelay = copies_arrive_queue.shift
      delay_queue << arriveDelay
      if (! arriveDelay.nil?) then copies_arrive_queue.push(arriveDelay + CYCLE_TIME) end
    end
    delay_queue
  end

  def get_delay_queue_and_current_backorder
    delay_queue = get_delay_queue
    { :queue => delay_queue, :current_backorder => delay_queue[-1 * EXTRA_QUEUE_PLACES]}
  end


  # Update the cached time-based simulation.
  #

  def update_product_delays
    start = before = Time.now
    queue_hash = get_delay_queue_and_current_backorder
    queue = queue_hash[:queue]
    backorder = queue_hash[:current_backorder]
    
    # figure out what ordinal the next as-yet-unplaced LI is, so that we can save it special in the db cache
    #
    ordinal_for_next_li = lis_for_delay_calculation.size + 1
    product_delays.destroy_all

    # instead of using multiple ProductDelay.create!() calls
    # we batch it all up and do it in 1 SQL insert
    #
    insert_string = "insert into product_delays (product_delay_id, product_id, ordinal, days_delay, created_at, updated_at) values "
    insert_args = []
    queue.each_with_index do |delay, ordinal|
      insert_args << "( NULL, #{product_id}, #{ordinal}, #{delay}, NOW(), NOW())"
      if ordinal == ordinal_for_next_li
        insert_args << "( NULL, #{product_id}, #{ProductDelay::MAGIC_NEXT_ORDINAL}, #{delay}, NOW(), NOW())"
      end
    end
    insert_string += insert_args.join(", ") + ";"
    ret = self.class.connection.execute(insert_string)
    raise "error - #{ret}" unless ret.nil?
  end

  #:::::
  #  use the cached results
  #:::::

  # return the delay in days
  #
  # special ordinal value '999' means "the next one not already tagged for an existing LI" 
  def get_delay(ordinal = ProductDelay::MAGIC_NEXT_ORDINAL)
    ProductDelay.find_by_product_id_and_ordinal(product_id, ordinal).andand.days_delay
  end

  # alias for backwards compatibility
  def days_backorder()
    get_delay || 0
  end

  #----------
  # purchasing
  #----------

  # NOTE: this is currently ignored
  # see update_tobuy()
  #
  def copies_needed()
    verboseP = false
    return [0,0] if (self.is_a?(UnivStub) || 0 == display? || false == in_print || (vendor.name == "smartflix.com")) 
    
    # Find all orders that we'd really like to fill, but can't.
    #
    # (i.e.: are uncancelled, haven't been shipped, aren't throttled.
    # This last bit is important: if we havent shipped Arc Welding 2
    # to Joe Sixpack bc he's throttled / at his quota, then we don't
    # really need to rush out an purchase another copy.)
    #
    # For universities, if someone is waiting for 90 DVDs, we can ship
    # him SOMETHING.  If he's waiting for just 6, we'd better get
    # copies of all of those in stock ASAP.
    #
    # Note that we ignore those line items that have orders that have
    # invalid customers (legacy buggy data from 2005).  Why ignore
    # them?  Because there are just 40 such items, and the straight
    # forward code blows up, and the working code is ugly.
    #
    # Then sort by the date the order arrived, then iterate through
    #     XYZFIX P3: doesn't deal with preconds, etc.
    #
    
    
    #     total_pain = 0
    #     needed = 0
    #     painful_customers = 0
    #
    #     lis = lis_for_delay_calculation
    #     copies_arrive_queue = copies_arrive()
    #     lis.each do |li|
    #       arriveDelay = copies_arrive_queue.shift
    #       pain = (arriveDelay.nil? ? 1000 : (Date.today + arriveDelay - li.order.orderDate))
    #       # only buy a copy if the pain is > 10 days AND we can minimize the
    #       # if we do buy a copy, note for the rest of this simulation that it will arrive soon
    #       #
    #       purchase_delay = (self.vendor.vendor_mood.andand.moodText == "hostile") ? VENDOR_ORDER_DELAY_HOSTILE : VENDOR_ORDER_DELAY_FRIENDLY
    #       if ((pain > PAIN_THRESHOLD) &&
    #           (arriveDelay.nil? ||
    #            (arriveDelay > purchase_delay)) )
    #         needed = needed + 1
    #         painful_customers += 1
    #         # print "XXX 4a: arriveDelay = #{arriveDelay} ... pain = #{pain}: purchase a copy\n"
    #       else
    #         # print "XXX 4b:  arriveDelay = #{arriveDelay} ... pain = #{pain}: don't purchase a copy\n"
    #       end
    #       total_pain = total_pain + pain
    #       if (! arriveDelay.nil?) then copies_arrive_queue.push(arriveDelay + CYCLE_TIME) end
    #
    #    end
    #
    #     # special case to handle
    #     if (lis.empty? && copies_arrive_queue.empty? && display?)
    #       needed = 1
    #       total_pain = 0.9
    #     end
    #
    #     puts "...#{needed}, #{total_pain.to_f}, #{painful_customers}" if verboseP
    #
    #     # 2 customers, each with pain X, is worse than 1 customer w pain X.
    #     # 2 customers, each with pain X, is not as bad as 1 customer with pain 2X.
    #     # conclusion: divide total pain by sqrt of customers.
    #     return [ needed, total_pain.to_f / Math::sqrt(painful_customers)]
    li_sf_cnt = unshipped_lis_sf.size 
    li_uni_cnt = unshipped_lis_sf.size / 10
    li_total = (li_sf_cnt + li_uni_cnt).round


    good_copies = Copy.good(self).size.to_i
    existing_copies = good_copies + quant_ordered 

    # 3 lis per copy is the worst we can tolerate
    desired_copies = (li_total / 3).ceil

    needed = desired_copies - existing_copies 
    needed = [0, needed].max    
    
    pain = needed * needed
    
    if existing_copies == 0
      pain = 1000
      needed = [needed, 1].max
    end
    
    if (! display?) || (! in_print)
      pain = 0
      needed = 0
    end
    
    [ needed, pain ]
  end


  def pain
    (tobuy.andand.pain).to_i
  end


  # Nightly recalc.  Figure out how many copies needed and cache.
  #
  #   Expensive, so we don't want to recalc the entire purchasing page
  #   (say, 300 titles!) on the fly.
  #
  # SHOULD do a full mini-simulation (used to do this!)
  #
  # ACTUALLY does a crappy-simulation.
  #
  def update_tobuy
    # XYZFIX P1 - this is a shitty algorithm.

    num_copies, pain = copies_needed()

    tb = tobuy || Tobuy.new(:product_id => product_id, :quant => -1, :pain => -1)
    tb.update_attributes(:quant => num_copies, :pain => pain)

    return [ num_copies, pain]
  end

  #----------
  # images
  #----------

  def pictureFile()
    "#{File.dirname(__FILE__)}/../../../../www/vidcaps/videocap_#{product_id}.jpg"
  end

  def pictureUrl()
    return "http://smartflix.com/vidcaps/lvidcap_#{product_id}.jpg"
  end

  def pictureP()
    return File.exists?(pictureFile)
  end

  def url(ctcode = nil)
    "http://smartflix.com/store/video/#{product_id}" + (ctcode.nil? ? "" : "?ct=#{ctcode}")
  end

  def short_url(ctcode = nil)
    "http://smartflix.com/s/#{product_id}" + (ctcode.nil? ? "" : "?ct=#{ctcode}")
  end





  # Return the first product in the set, if this product is in a set, or the product
  def base_product
    if self.product_set
      return self.product_set.products.first
    else
      return self
    end
  end

  # Return the birthdate of the first copy
  def birth_date
    earliest = self.copies.find(:first, :order => 'birthDATE ASC')
    return earliest.birthDATE if earliest
  end


  # What is the ordinal of this product in the set?
  def product_set_ordinal
    product_set_membership.ordinal
  rescue
    nil
  end


  # Make products sortable (by their ID)
  def <=>(other)
    self.id <=> other.id
  end

  # Get the name this product should be listed under; for individual
  # products it's just the product name, but for sets it's the set name
  def listing_name()
    product_set_member? ? product_set.name : name
  end

  # Give a fully specified listing name that includes disc number
  def listing_name_with_disc_number()
    product_set_member? ? "#{product_set.name} (Disc ##{product_set_ordinal})" : name
  end

  def useful_description?()
    ( ! product_set_member?)   ||
      product_set_ordinal == 1 ||
      product_set.describe_each_title?
  end

  # Return a summary of the description, basically the initial part of
  # it but chopped nicely at a word boundary
  #
  # keywords: description
  #           short shorten
  def summary(len = 60)
    if description.size <= len
      summary = description
    else
      split = description.rindex(' ', len)
      split = len if split.nil?
      summary = description[0,split]
    end
    summary.gsub(/<[^>]*>/, ' ')
  end

  # Return the data added for sorting, so set a really early date for
  # 0000-00-00 instead of using nil
  def date_added_for_sort
    # Note that Date.civil returns julian day 0 (a year of -4712)
    date_added ? date_added : Date.civil()
  end

  # Generate a companion for a product, for the "rent this together
  # with that" feature.  I observe here that it would be nice if we
  # filtered out stuff that was already in the shopping cart and chose
  # the next item down the sorted list of recommendations.
  def rent_together_recommendation()
    
    recommendations = Hash.new(0)

    # Get the recommendations for the given product, and weight them by
    # index.
    self.product_recommendations.each_with_index do |recommended_product, i|
      recommendations[recommended_product] += (MAX_PRODUCT_RECOMMENDATIONS - i) if !recommended_product.backordered?(0)
    end

    # Return the pair of items
    return self, recommendations.sort { |a, b| b[1] <=> a[1] }.collect { |v| v[0] }[0]
  end

  # Return any wiki pages associated with this products category or parent category
  def wiki_pages
    self.categories.map do |cat|
      cat.wiki_pages + (cat.parent ? cat.parent.wiki_pages : [])
    end.flatten.uniq
  end

  def url_tracks
    UrlTrack.find_by_sql("SELECT * 
                          FROM   url_tracks
                          WHERE  action = 'video'
                          AND    action_id = #{id}")
  end


  #----------
  # cobrand
  #----------
  def oreilly_make_url()
    url().gsub(/smartflix/, "makezine.smartflix")
  end

  def oreilly_craft_url()
    url().gsub(/smartflix/, "craftzine.smartflix")
  end


  #==================================================
  #==================================================
  #              class methods
  #==================================================
  #==================================================


  def self.purchase_price_to_rental_price(purch)
    return(9.99)   if purch < 70
    return(14.99)  if purch < 120
    return(19.99)
  end


  #
  # Return a list of featured products, for presentation on the front page
  # and within non-leaf category pages; takes the approximate number of
  # products to display and a list of categories to ignore and returns a
  # list of product_ids
  #
  def self.get_featured(num_to_display = 150, minstock = 2, skipcats = [113])

    # First get all products, sorted by how often they've rented in last 180 days,
    # only including products with at least minstock items in stock

    products = Product.find_by_sql("SELECT orderCount.* FROM

                                   (SELECT line_items.product_id, count(1) AS numOrders
                                      FROM orders, line_items
                                 LEFT JOIN product_set_memberships ON product_set_memberships.product_id=line_items.product_id
                                     WHERE line_items.order_id=orders.order_id
                                       AND line_items.live=1
                                       AND (product_set_memberships.ordinal=1 OR ISNULL(product_set_memberships.ordinal))
                                       AND orders.orderDate >= DATE_SUB(CURDATE(), INTERVAL 180 DAY)
                                  GROUP BY line_items.product_id) AS orderCount,

                                    (SELECT copies.product_id,
                                            COUNT(IF(copies.inStock=1 AND copies.status=1,1,NULL)) AS inStock
                                       FROM copies, products
                                      WHERE copies.product_id=products.product_id
                                        AND products.display=1
                                   GROUP BY product_id) AS stockCount

                                 WHERE orderCount.product_id=stockCount.product_id
                                   AND stockCount.inStock >= #{minstock}
                              ORDER BY numOrders DESC")

    # Now find out how many from each category, based on how often the category rents
    cat_rental = Hash.new(0)
    total_rentals = 0
    products.each do |product|
      product.categories.each do |cat|
        next if (skipcats.include?(cat.category_id) || skipcats.include?(cat.parent_id))
        cat_rental[cat.category_id] += product.numOrders.to_i
        total_rentals += product.numOrders.to_i
      end
    end

    # Calculate number of recommendations per category, based on ratio of rentals in each category
    cat_count = Hash.new(0)
    cat_rental.each do |category_id, count|
      cat_count[category_id] = ((count.to_f / total_rentals.to_f) * num_to_display.to_f).round
    end

    # Now, get that many from each category from the initial list (top
    # items first -- they're already sorted)

    featured = Array.new()

    products.each do |product|
      # See if there are any slots left for any of the categories this product belongs to
      product.categories.each do |cat|
        if (cat_count[cat.category_id] > 0)
          featured << Product.find(product.id)
          cat_count[cat.category_id] -= 1
          break
        end
      end
    end

    return featured

  end


  # Return the new titles, filtering the results to include only the
  # first item from each set; caller can specify :limit as an option
  def self.find_new_for_listing(options = {})
    options.assert_valid_keys(:limit)
    options[:select] = 'products.*'
    options[:joins] = 'LEFT JOIN product_set_memberships ON products.product_id=product_set_memberships.product_id'
    options[:conditions] = "date_added != '0000-00-00' AND (ISNULL(ordinal) OR ordinal=1) AND products.display=1"
    options[:order] = 'date_added DESC, products.product_id DESC'
    options[:limit] = 50 if (!options[:limit])
    Product.find(:all, options)
  end

  # Get the highest rated products; caller can specify :limit and :category as options
  def self.find_top_rated_for_listing(options = {})
    options.assert_valid_keys(:limit, :category)
    options[:select] = 'products.*, AVG(ratings.rating) AS avg_rating, COUNT(ratings.rating) AS num_ratings'
    options[:joins] = 'JOIN ratings'
    options[:conditions] = 'products.product_id = ratings.product_id AND products.display = 1'
    options[:group] = 'products.product_id'
    options[:order] = 'avg_rating DESC, num_ratings DESC'
    options[:limit] = 40 if (!options[:limit])
    if (options[:category])
      options[:conditions] << " AND products.product_id = categories_products.product_id"
      options[:conditions] << " AND categories_products.category_id = categories.category_id"
      options[:conditions] << " AND (categories.category_id=#{options[:category].id} OR categories.parent_id=#{options[:category].id})"
      options[:joins] << " JOIN categories_products JOIN categories"
      options.delete(:category)
    end
    Product.find(:all, options)
  end

  # Rather than using the featured products model, shorthand to get
  # featured products. Configuration options: :order (default is
  # :linear, other option is :weighted_random), :limit (number of items
  # to return), :category (category to limit to), and :skip_products
  # (array of products to not include)

  def self.featured(options = {})

    options.assert_valid_keys(:limit, :order, :category, :skip_products, :include_universities)

    # Optimization, load up the product on initial query
    find_options = { :include => :product }

    find_options[:limit] = options[:limit]

    if (options[:order] == :weighted_random)
      find_options[:order] = '(featured_product_id + 5.0) * RAND()'
    else
      find_options[:order] = 'featured_product_id'
    end

    # Build up conditions for products to skip and category, starting with a default of only listing displayable
    conditions = ['products.display=1']
    if (options[:skip_products].is_a?(Product))
      options[:skip_products] = [options[:skip_products]]
    end
    if (options[:skip_products].instance_of?(Array) && options[:skip_products].size > 0)
      conditions << "featured_products.product_id NOT IN (#{options[:skip_products].collect { |p| p.id }.join(',')})"
    end
    if (options[:category])
      conditions << "products.product_id = categories_products.product_id"
      conditions << "categories_products.category_id = categories.category_id"
      conditions << "(categories.category_id=#{options[:category].id} OR categories.parent_id=#{options[:category].id})"
      # This condition requires an additional join and a group by
      find_options[:joins] = 'JOIN categories_products JOIN categories'
      find_options[:group] = 'products.product_id'
    end
    if (conditions.size > 0)
      find_options[:conditions] = conditions.join(' AND ')
    end


    featured = FeaturedProduct.find(:all, find_options).collect { |fp| fp.product }

    if options[:include_universities]
      if options[:category] 
        univs = options[:category].all_universities.map(&:univ_stub)
        if univs
          featured = univs + featured
          featured = featured[0, options[:limit]]
        end
      else
        # XYZFIX P3: we might get a univ stub that we already got for
        # one of the featured categories
        featured = (featured << UnivStub.find(:all, :limit => 6, :order => 'RAND()')).flatten.sort_by {rand}[0, options[:limit] ]
      end
    end

    featured.compact
  end

  # for use by the postcheckout-upsell: given one or more products,
  # what are some other products like them (same cats, good ratings, etc.)
  def self.other_products_in_categories(products)
    products.map {|product| product.categories.first}.select {|cat| cat }.uniq.
      map{|cat| cat.listable_products('toprated')}.flatten.uniq.
      sort_by { |p| p.avg_rating ? (6.0 - p.avg_rating) : 6.0 }
  end


  # Return all titles that match the search string, using ferret, but
  # filter the resulting list to include only displayable items and the
  # first item from each set
  def self.find_by_contents_for_listing(query)

    # Note: We limit products here to a maximum of 150, since we don't
    # currently do any sort of pagination, but this might limit the
    # search results to an odd number since some search results may get
    # pruned due to the whole sets thing, so we then limit the results
    # to 100 to get a round number more often than not

    products = self.find_by_contents(query, :limit => 150)
    products = products.collect { |p| p.product_set_member? ? p.product_set.first : p }.uniq
    return products.select { |p| p.display? }[0,100]
  end

  # Given a list of products, filter them for listability (ie first in set) and sort them as directed
  def self.select_listable_and_sort(products, sort_option)

    # First filter out those where display is not desired
    products = products.select { |p| p.display? }

    # We sort and filter for set membership here in the code rather than
    # in the DB where the original query is made to get the code written
    # faster; this is slow, so if it's a performance bottleneck we'll
    # change that

    # XXXFIX P3: Determine if performance bottleneck, not really if we page
    # cache things that use this, but if we ever don't cache...

    products = products.select { |p| !p.product_set_member? || (p.product_set_member? && p.product_set_ordinal == 1) }

    sort_option = (sort_option.nil? || sort_option.is_a?(String) ?  sort_option : sort_option.value )
    grped = products.group_by(&:class)

    products = grped[Video]
    case (sort_option)
    when 'newest'
      products.sort! { |a, b| b.date_added_for_sort <=> a.date_added_for_sort }
    when 'oldest'
      products.sort! { |a, b| a.date_added_for_sort <=> b.date_added_for_sort }
    when 'toprated'
      # XXXFIX P4: Should number of ratings be factored in here?
      products = products.sort_by { |p| p.avg_rating ? (6.0 - p.avg_rating) : 6.0 }
    else
      products.sort! { |a, b| a.name <=> b.name }
    end
    
    return (grped[UnivStub] + products)

  end

  def self.most_popular(count=30)
    results = connection.execute("SELECT product_id, COUNT(line_item_id) " +
                                 "AS popularity FROM line_items " +
                                 "GROUP BY product_id " +
                                 "ORDER BY popularity DESC LIMIT 30")
    
    find(results.map { |h| h[0].to_i  })
  end

  # quick, fixed $2 discount on item added to cart, redirected to
  # checkout page: TODO rejigger things so the discount can be
  # parameterized and encoded in the auth token for
  # verification/tamper prevention --nzc Tue Sep  9 11:45:20 2008
  def self.create_quick_discount_link(customer_id, product_id)
    OnepageAuthToken.create_token(Customer.find(3), 3, :controller => 'cart', :action => 'quick_discount', :id => product_id)
  end


  def self.DATAMINE_languishing
    # FAR TOO SLOW!!!!!
    # ----------------
    #     candidates = Hash.new
    #     @products = Product.find(:all).reject { |tt| ! tt.product_set_ordinal.nil? && tt.product_set_ordinal > 1}
    #     @products.each do |tt|
    #       cnt = tt.copies.select { |cc| cc.status == 1 && cc.inStock == 1 && cc.mediaformat == 2}.size
    #       waiting = tt.line_items.select {  |li| li.shipment_id.nil? && li.live == 1}.size
    #       surplus = cnt - waiting
    #       candidates[tt] =  surplus if surplus > 5
    #     end
    #     candidates

    ret =
    Product.connection.select_all("SELECT *  FROM
                                     (SELECT productCount.product_id, cnt-open_orders as free FROM

                                         (SELECT products.product_id, name, count(1) as 'cnt'
                                         FROM products, copies
                                         WHERE products.product_id = copies.product_id
                                         AND  copy.status = 1
                                         AND copy.inStock = 1
                                         AND mediaFormat = 2
                                         GROUP BY products.product_id
                                         ORDER BY cnt desc) productCount,


                                         (SELECT products.product_id, count(IF(ISNULL(line_item_id), NULL, 1)) as open_orders
                                         FROM products left join line_items on products.product_id = line_items.product_id
                                         AND line_items.live = 1
                                         AND ISNULL(shipment_id)
                                         GROUP BY products.product_id) liCount

                                     where productCount.product_id = liCount.product_id
                                     order by free desc) prelim where free > 5;")
    languishing = Hash.new
    ret.each do |row|
      tt= Product.find(row["product_id"])
      languishing[tt] = row["free"]
    end
    languishing
  end

  def self.DATAMINE_languishing_pretty
    lang = Product.DATAMINE_languishing
    newlang = Hash.new {|hash, key| hash[key]  = []}
    lang.each_pair {  |tt, count|  newlang[count] << tt}
    newlang.keys.sort { |a,b| a.to_i <=> b.to_i }.reverse.each { |count| newlang[count].each { |tt| puts "#{ "%2i" % count} - (#{ "%4i" % tt.id})  #{tt.name}  "} }
    nil
  end

  def self.ERRORCHECK_no_categories
    Product.find_by_sql("SELECT products.* 
                       FROM  products
                       LEFT JOIN categories_products 
                       ON products.product_id = categories_products.product_id 
                       WHERE ISNULL(category_id)
                       AND products.product_id NOT IN (3603, 5834, 5835, 5836, 6401)")
  end

  def self.ERRORCHECK_no_vendor
    Product.find_by_sql("SELECT * FROM (SELECT p.*, v.vendor_id as 'missing' 
                                        FROM products p 
                                        LEFT JOIN vendors v 
                                        ON p.vendor_id = v.vendor_id) zzz 
                                  WHERE ISNULL(missing)")
  end
  


  # If we've got 0 live copies of something, and 0 people are waiting for it, it MIGHT
  # be an out-of-print product that we want to remove...or it might not be.
  #
  # Be very careful making decisions based on this data.
  #
  # Also, this function is very slow.  Not for use in controllers / views.
  #
  def self.candidates_for_removal_from_website
    Product.find(:all).select { |product| ; 0 == product.unshipped_lis.size && 0 == product.numLiveCopies_noting_very_late }
  end
  
  def self.no_prices_on_overdue
    LineItem.late_items_warnable.map(&:product).uniq.select { |product| product.purchase_price.nil?}.sort_by { |product| product.id}
  end



end


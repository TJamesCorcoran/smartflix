class University < ActiveRecord::Base
  attr_protected # <-- blank means total access

  cattr_accessor :logger
  
  self.primary_key = 'university_id'
  
  belongs_to :category

  belongs_to :featured_product, :polymorphic => true
#  has_many :adwords_ads, :as => :thing_advertised
#  has_many :other_ads
  has_many :customers, :through => :orders
  has_many :orders

  has_many :university_curriculum_elements
  has_many :university_host_names
  has_one  :univ_stub
  has_many :univ_inventory_infos
  has_many :products, :through => :university_curriculum_elements
  
  alias_method :domains, :university_host_names
  
  #------------------------------
  # utility / compatibility / data funcs
  #------------------------------

  def first_month_charge
    SmartFlix::Application::FIRST_MONTH_FREE ? 0.01 : subscription_charge
  end

  def self.base_plan_price
    University.find(:all).map(&:subscription_charge).min
  end

  def self.min_plan_price
    univ = University.find(:all).min_by(&:subscription_charge).subscription_charge_for_n(1)
  end

  def self.max_plan_price
    univ = University.find(:all).max_by(&:subscription_charge)
    univ.subscription_charge_for_n(3)
  end

  # def increase_2011
  #   increase = 1.99
  #   apply_increase =   (Date.today > Date.parse("15 Nov 2011"))
  #   apply_increase ? increase : 0.0
  # end

  # this extra argument should be removed soon
  def plans()
    base = attributes["subscription_charge"]
#    base += increase_2011 if add_2011

    { 1 => BigDecimal((base * 0.53).round(2).to_s),
      2 => BigDecimal((base * 0.87).round(2).to_s),
      3 => BigDecimal((base * 1.00).round(2).to_s),
      4 => BigDecimal((base * 1.20).round(2).to_s),
      6 => BigDecimal((base * 1.60).round(2).to_s),
      8 => BigDecimal((base * 1.87).round(2).to_s)
    }
  end

  REGULAR = 1
  PREMIUM = 2
  ULTRA_PREMIUM = 3

  def premium?
    (charge_level == PREMIUM || charge_level == ULTRA_PREMIUM)
  end

  def subscription_charge_for_n(n)
    base = attributes["subscription_charge"]
    price = plans[n.to_i]
    raise "illegal subscription size #{n}" unless price

    price
  end
  
  def number_per_month(subscription_charge)
    raise "expect input as BigDecimal, not #{subscription_charge.class}" unless subscription_charge.is_a?(BigDecimal)

    base = attributes["subscription_charge"]

    # special note: customers who get the 50% or 100% off deal s
    return 3 if (  (base / 2 ) == subscription_charge ||
                   ((base + BigDecimal("0.01")) / 2 ) == subscription_charge )
    return 3 if subscription_charge == BigDecimal("0.01")
    return 3 if subscription_charge == BigDecimal("0.0")

    number = plans.invert[subscription_charge]

    # this should be removed soon
    if number.nil? && Date.today < Date.parse("2011-12-17") 
      number = plans(false).invert[subscription_charge]      
    end

    raise "illegal amount #{subscription_charge.to_f} for base #{base}" unless number

    number
  end


  def subscription_charge_discount
    return subscription_charge / 2
  end

  def self.price_to_charge_level(subscription_charge)
    ret = { 22.95 => 1, 25.95 => 2, 27.95 => 3}[subscription_charge.to_f]
    raise "undefined! #{subscription_charge}" unless ret
    ret
  end


  def self.UNIV_RESEARCH_compute_price(avg_purch_price)
    return 22.95 if avg_purch_price < 40 
    return 25.95 if avg_purch_price < 60 
    return 27.95 if avg_purch_price < 80 
    raise "unexpectedly high price #{avg_purch_price}"
  end


  #------------------------------
  # utility / compatibility / data funcs
  #------------------------------

  def display_product
    featured_product || products.first
  end

  
  def days_backorder() 0 end
  def product_set_ordinal() nil end
  def canonical_hostname()    university_host_names.first.hostname  end
  def primary_domain()    domains.first.hostname  end

  # all orders that have elements left to ship ... even if the customer is not paid up
  def orders_with_items() orders.select {|o| o.line_items_unshipped_and_uncancelled.any? } end

  # subset of above: winnow to just those custs who are paid up
  def live_orders() orders.select {|o| o.live_university_at?} end

  def live_customers() live_orders.map(&:customer) end


  def potential_customers() category.customers - customers end
  
  #------------------------------
  # univ name: noun, verb, etc., etc. 
  #------------------------------
  
  def as_filename
    name.downcase.gsub(/ /,"_")
  end
  
  def name_short()
    name.match(/^(.*) University/)
    "#{$1} U"
  end
  
  def name_noun()
    name.match(/^(.*) University/)
    "#{$1}"
  end


  
  # for Woodturner University -> "turning"
  # for Glasswork -> "glass"
  def skill()    category.name.downcase  end
  def name_verb() verb_str || skill   end


  def top_vendors()
    products.group_by(&:vendor).map { |vendor, productlist| [productlist.size, vendor]}.sort_by { |pair| pair[0]}.reverse[0,6].map{|pair| pair[1] }
  end
  
  # same as above, but remove amazon and output as strings
  def top_vendors_for_ads()
    top_vendors.reject { |x| x.name == "Amazon.com" }.map(&:name)
  end

  def top_authors
    # sort_by_frequency() 
    # in railscart/vendor/plugins/basichacks/lib/enumerablehack.rb
    # doesn't do what we want.
    
    # Note that we benefit from eager pre-loading of
    # curriculum_elements and products done in controller - cuts db
    # queries by 40% ...
    products.group_by(&:author).map { |author, productlist| [productlist.size, author]}.sort_by { |pair| pair[0]}.reverse[0,6].map{|pair| pair[1] }
  end
  
  
  
  #------------------------------
  # manipulate curriculum
  #------------------------------
  
  def destroy_with_children
    univ_stub.andand.destroy
    destroy_self_and_children([:university_host_names,  :university_curriculum_elements])
  end
  
  def remove_product(product)
    verbose = Rails.env != "test"
    puts "Removing '#{product.name}' from '#{name}' university" if verbose
    university_curriculum_elements.select { |ce| ce.product == product }.each { |ce| ce.destroy }
    orders.map(&:line_items_unshipped_and_uncancelled).flatten.select { |li| li.product == product }.each do  |li|
      puts " * cancelling #{product.name} from order #{li.order.order_id} by #{li.order.customer.email}" if verbose
      begin
        li.cancel(true)
      rescue
      end
    end
  end

  def add_product(product)
    verbose = Rails.env != "test"
    puts "Adding '#{product.name}' to '#{name}' university" if verbose
    
    if products.include?(product)
      puts " ! already present #{product.name}" if verbose
      return
    end
    
    university_curriculum_elements << UniversityCurriculumElement.new(:product => product)
    orders_with_items.each do |o|
      puts " * adding #{product.name} to order #{o.order_id} by #{o.customer.email}" if verbose
      o.line_items << LineItem.new(:order => o, :product => product, :price => 0.00)
    end
  end

  
  #------------------------------
  # inventory levels
  #------------------------------
  
  # University.find(:all).each { |univ| puts "#{univ.inventory_shortfall}  #{univ.name}" }
  
  # We could use 'live_orders' here instead of 'orders', but that doesn't change anything -
  # once we invoke 'shippable_count...', we're already pruning out orders that aren't paid up to date, are cancelled, etc.
  #
  def inventory_shortfall
    on_order_count = products.map { |product| product.quant_ordered }.sum
    
    # NOTE: we could use live_orders() instead of orders() here, but
    # we end up capturing that anyway w the
    # shippable_count_for_univ(), which looks at the same facts
    
    shortfall = orders.map { |o| 
      if o.customer.nil?
        # puts "no customer for order #{o.id}"
        0
      else
        o.customer.shippable_count_for_univ(o.university, o.customer.potential_shipments.map(&:potential_items).flatten.size).to_i 
      end
    }.sum
    [ shortfall, shortfall - on_order_count]
  end

  # OK, now we know that we want to buy 15 things for this univ.
  # ... but which things?

  # 1) spread the pain out in some reasonable way across the products
  # 2) update the 'tobuy' info on the products to capture this
  #
  # XYZFIX P2 - this is a crappy algorithm
  #   * should incr entire sets equally (not 3 copies of vol 1 and 0 copies of vol 2)
  #   * should incr across all items in univ more equally ... not try
  #      to front load onto just a few items
  def update_tobuy

    # we computed how many each univ needs elsewhere
    total = num_needed = [0, univ_inventory_infos.last.shortfall_one_week.to_f].max.to_i

    # only try to buy from good vendors
    prods = products.reject(&:hostile?)
    num_prods = prods.size.to_f
    num_good = prods.map { |p| p.num_circulating_copies }.sum

    # what's the target quantity for each product?
    # if we already have
    #   prod1 ->  1 copy
    #   prod2 ->  2 copies
    #   prod3 -> 10 copies
    # ...and we need 5 new copies, then we're aiming for 18 copies total, and split evenly that'd be
    #   prod1 ->  6 copies
    #   prod2 ->  6 copies
    #   prod3 ->  6 copies
    # ... so our "target" is 6 copies for each product
    #
    # XYZFIX P2 - can already see a bug here - we can't take prod3
    # down from 10, so our target is actually:
    #   prod1 ->  4 copies
    #   prod2 ->  4 copies
    #   prod3 ->  10 copies
    #
    target_quant = (num_good + num_needed) / num_prods
    
    @@logger.info "  * #{sprintf("%-42s", name)} - spreading #{num_needed} across #{num_prods.to_i} titles"  
    return if num_needed <= 0 
    
    # We want to add copies of things we're short of.  
    # Sort the products with products with 0 copies up front, and prods w 100 copies at the end
    #
    prods.sort { |p1, p2| p1.num_circulating_copies <=> p2.num_circulating_copies  }.each do |p|
      next if num_needed <= 0 
      
      num_to_add = (target_quant - p.num_circulating_copies ).round.to_i
      num_to_add = [num_to_add, num_needed].min.to_i
      
      if (num_to_add > 0) 
        @@logger.info "    * adding #{num_to_add} (#{p.tobuy.quant} -> #{p.tobuy.quant + num_to_add}) to #{p.id} / #{p.name}"
        
        # belt-and-suspenders
        p.update_tobuy if p.tobuy.nil?

        # update the tobuy
        #
        tb = p.tobuy 
        tb.update_attributes!(:quant  => (tb.quant + num_to_add))
      
        # note that we've applied some of the to-buy juice to this
        # product; less for next product
        #
        num_needed -= num_to_add
      end
            
    end

    return(total)
  end
  
  #------------------------------
  # class methods
  #------------------------------

  # Anything with a positive number is already backlogged.  Anything with
  # a zero is OK.  I think the negative numbers are spurious (reships
  # because of various reasons).
  #
  def self.tightness
    University.find(:all).each { |u| puts "    *#{u.inventory_shortfall[0]} //  #{u.name}"  }
  end
  
  def self.enrollment_report
    find(:all).each do |university|
      LOGGER.info "#{university.name}:"
      Order.find_all_by_university_id(university.id).each do |order|
        customer = order.customer
        remaining = order.line_items.count { |item| item.pending? }
        if remaining > 0
          LOGGER.info "  Customer #{customer.id} (#{customer.last_name}, #{customer.first_name}) enrolled, #{remaining} videos remaining."
          if order.univ_fees_current?
            LOGGER.info "    fees current."
          elsif (order.find_most_recent_payment.successful)
            LOGGER.info "    fees due."
          else
            LOGGER.info "    last charge failed -- fees due."
          end
        end
        LOGGER.info ""
      end
      LOGGER.info "-----------------------------------------------------------------------\n"
    end
  end
  
  def self.find_by_hostname(hostname)
    UniversityHostName.find_by_hostname(hostname).andand.university
  end
  
  def self.customers
    University.find(:all).map(&:customers).flatten
  end
  
  # find the most popular universities ... and do it QUICKLY.  We
  # could do all this in Ruby, but it would take a minute, and then
  # we'd have to cache the results
  #
  def self.most_popular(n = 5)
    cache_key = "#{self.class.name}:week_#{Date.today.cweek}:most_popular_{n}"

    Rails.cache.fetch(cache_key) { 
      University.find_by_sql("SELECT * 
                            FROM universities
                            WHERE university_id in
                               (SELECT university_id 
                                FROM
                                    (SELECT university_id, count(1) as cnt
                                     FROM orders 
                                     WHERE university_id 
                                     GROUP by university_id ) zzz 
                                ORDER by cnt DESC) 
                             LIMIT #{n}")
    }
  end

  # XYZ FIX P4 - should this func be renamed to conform to Ruby norms?
    def self.create_new(args)
    verbose = Rails.env != "test"

      args.allowed_and_required([:title_id_list, :name, :category, :domains, :price, :featured_product],
                                [:title_id_list, :name, :category] )
      args[:domains] ||= []
      
      product_id_list = args[:title_id_list].map { |entry|
        case entry
        when String
          set = ProductSet.find_by_name(entry)
          if set
            puts "set = #{entry} ; products = #{set.products.map(&:name).join(', ')}" if verbose
            set.products.map(&:id)
          else
            product = Product.find_by_name(entry)
            raise "no product found for '#{entry}'" if product.nil?
            puts "product = #{product.name}" if verbose
            product.id
          end
        when Fixnum
          entry
        end
      }.flatten.uniq
      
      
      this_cat = args[:category].is_a?(Category) ? args[:category] : Category.find(args[:category])
      args[:price] ||= UNIV_RESEARCH_compute_price(product_id_list.map {|tid| Product.find(tid).purchase_price }.average)
      args[:charge_level ] = self.price_to_charge_level(args[:price])

      # actual ctor
      university = University.create!(:name => args[:name], 
                                      :subscription_charge => args[:price], 
                                      :category => this_cat, 
                                      :charge_level => args[:charge_level],
                                      :featured_product => args[:featured_product])
      args[:domains].each {  |domain_name|  UniversityHostName.create!(:hostname => domain_name, :university => university) }
      product_id_list.each do |product_id| 
        puts "    product = #{product_id} // #{Product.find_by_product_id(product_id).name}" unless Rails.env == "test"
        UniversityCurriculumElement.create!(:video_id => product_id, :university => university) 
      end
      puts "    ... #{product_id_list.size} items" unless Rails.env == "test"
      UnivStub.create_stub(university)
      university
    end

end

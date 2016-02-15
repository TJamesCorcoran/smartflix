ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'


class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
#  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
#  self.use_instantiated_fixtures  = false
  
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all
  
  # Add more helper methods to be used by all tests here...
  
  # Expand TestRequest and TestSession classes to have pieces requested by origin tracking
  class ActionController::TestRequest
    def user_agent
      'Test User Agent'
    end
    def referer
      ''
    end
  end
  
  class ActionController::TestSession
    
    def model
      # Need to return something that responds to :id
      o = Object.new
      def o.id
        0
      end
      return o
    end
  end
  
  
  DEFAULT_UNIV_RATE = 3
  
  def build_unfilled_orders(cust, vendor, cat, customer_data, unfilled_order_names )
    #----------
    # iterate through orders that are not in the field, create them
    #
    
    
    unfilled_order_names.each do |order_name|
      order_data = customer_data[order_name]
      
      university_id = University.find_by_name(order_data[:server_name]).andand.id
      raise "univ_dvd_rate only applicable to universities" if order_data[:univ_dvd_rate] && ! university_id        
      raise "need univ_dvd_rate for universities - #{order_data.inspect}" if ! order_data[:univ_dvd_rate] && university_id        
      
        hh = {:orderDate => order_data[:orderDate],
          :server_name => order_data[:server_name],
          :university_id => university_id,
          :univ_dvd_rate => order_data[:univ_dvd_rate],
          :live => order_data[:live].nil? ? true : order_data[:live] ,
          :customer => cust }
        hh[:unshippedMsgSentP] = false
        order = Order.create!(hh)
        
        
        # put 1 or more payments on this order
        if university_id
          amount = University.find(university_id).subscription_charge_for_n(order_data[:univ_dvd_rate] || DEFAULT_UNIV_RATE)
        else
          amount = order_data[:lis].size * 9.99
        end
        
        if order_data[:payments]
          order_data[:payments].each do |payment|
            
            Payment.record_timestamps = false
            payment = Payment.create!(:order_id => order.order_id,
                                      :created_at => payment[:date],
                                      :updated_at => payment[:date],
                                      :payment_method => "Credit Card",
                                      :amount_as_new_revenue => amount,
                                      :amount => amount,
                                      :customer_id => cust.customer_id,
                                      :status =>               payment[:status],
                                      :complete =>             payment[:complete] || false,
                                      :successful =>           payment[:successful] || false )
            Payment.record_timestamps = true
          end
        else
          payment = Payment.create!(:order_id => order.order_id,
                                    :updated_at => order_data[:orderDate],
                                    :amount_as_new_revenue => amount,
                                    :amount => amount,
                                    :payment_method => "Credit Card",
                                    :customer_id => cust.customer_id,
                                    :complete => order_data[:paid] || false,
                                    :successful => order_data[:paid] || false)
        end
        
        order.reload
        
        order_data[:lis].each do |li|
          product_text = li[:name] || "new order #{String.random_alphanumeric} "
          product = Product.find_by_name(product_text) 
          if product.nil?
            # have to do the next bit in lines, not 1 line of .create! because ":type => XXX" does not work,
            # because that's an obsolete keyword (see http://wiki.rubyonrails.org/rails/pages/SingleTableInheritance)
            hh = { :name => product_text,
              :categories => [cat],
              :price => 9.99,
              :author_id => 1,
              :vendor => vendor,
              :description => "foo",
              :purchase_price => 49.99 }
            hh[:date_added] = Date.today 
            product = Product.new(hh)
            product[:type] = li[:giftCert] ? "GiftCert" : "Video"
            product.save!
            
            li[:inStock] ||= li[:instock]
            
            copy = Copy.create!(:product_id => product.product_id,
                                :birthDATE => Date.today - 365,
                                :status => 1,
                                :inStock => li[:inStock] ? 1 : 0,
                                :visibleToShipperP => 1,
                                :mediaformat => 2,
                                :tmpReserve => 0) if ! li[:giftCert]
            
          end
          
          if li[:dateOut]
            shipment = Shipment.create!(:dateOut => li[:dateOut],
                                        :time_out => li[:dateOut].to_datetime,
                                        :boxP => false,
                                        :physical => true)
            copy = Copy.create!(:product_id => product.product_id,
                                :birthDATE => Date.today - 365,
                                :status => 1,
                                :inStock => li[:inStock] ? 1 : 0,
                                :visibleToShipperP => 1,
                                :mediaformat => 2,
                                :tmpReserve => 0) if ! li[:giftCert]
            
            
          end
          hh = {
            :product => product,
            :order => order,
            :dateBack => li[:dateBack],
            :shipment => shipment,
            :actionable => li[:actionable].nil? ? true : li[:actionable] ,
            :copy => copy,
            :queue_position => li[:queue_position],
            :live => ! li[:cancelled] }
          
          hh[:ignore_for_univ_limits] = li[:ignore_for_univ_limits].to_bool
          
          li = LineItem.create!(hh)
          
          
          order.line_items << li
        end
      end
  end
  
  
  def build_infield_data(cust, vendor, cat, customer_data, in_field_data)

    #----------
    # (OPTIONAL)
    # iterate through orders that are in the field, create them
    #
    in_field_data &&
      in_field_data.keys.each do |server_name|
      
      
      university_id = University.find_by_name(server_name).andand.id
      
      #  support the case where a univ has a few items in the field and a few not
      order = nil
      if university_id
        order = Order.find(:all, :conditions => "customer_id = #{cust.customer_id} AND university_id =#{university_id}").first
      end
      
      if ! order 
        order = Order.create!(:server_name => server_name.to_s, 
                              :university_id => university_id,
                              :customer => cust,
                              :unshippedMsgSentP => false,
                              :orderDate => (Date.today - 8))
        payment = Payment.create!(:order_id => order.order_id, 
                                  :updated_at => (Date.today - 8),
                                  :payment_method => "Credit Card",
                                  :customer_id => cust.customer_id,
                                  :complete => true,
                                  :successful => true)
      end
      shipment = Shipment.create!(:dateOut => (Date.today - 4),   # why 4 days?  If we
                                  # set it to 7 or more,
                                  # the SF ship rate
                                  # code will allow us
                                  # to send a second
                                  # shipment, which
                                  # confuses issues!
                                  :time_out => (Time.now - 60*60*24*7),
                                  :boxP => false, 
                                  :physical => true)
      in_field_data[server_name].times do |li_iter|
        product_text = "old order #{String.random_alphanumeric} "
        product = Product.create!(:name => product_text,
                                  :description => "foo",
                                  :date_added => Date.today,
                                  :vendor => vendor,
                                  :author_id => 1,
                                  :categories => [cat],
                                  :price => 9.99,
                                  :purchase_price => 49.99)
        copy = Copy.create!(:product_id => product.product_id, 
                            :birthDATE => Date.today - 365,
                            :status => 1,
                            :inStock => true,
                            :visibleToShipperP => 1,
                            :mediaformat => 2,
                            :tmpReserve => 0)
        li = LineItem.create!(:product => product, 
                              :copy => copy, 
                              :shipment => shipment,
                              :actionable => true,
                              :order => order)
        order.line_items << li
      end
    end
  end
  
  # This func will build zero or more shipped orders with in-the-field
  # items, and zero or more unshipped orders.  
  #   * Each Li is paired with a specific Product
  #   * There is exactly 1 copy for each  Product
  #
  # (You can reuse the same producttext to ensure 2 LIs waiting for a single copy) 
  #
  # This does not allow full generality.  
  # You can't, for instance, have
  #   * a single copy that's gone out more than once
  #   * a previous order that had more than one LI in it
  #   * etc.
  #
  # ...but it does allow you to build complicated histories with a
  # minimum of typing.
  #
  # Input is of the form
  # 
  # { :cust1 => { :in_field => {"smartflix" => 2,
  #                             "wood-u"    => 2,
  #                             "metal-u"   => 0},
  #                 :order1 => {   :orderDate => XXX,
  #                                :server_name => "smartflix",
  #                                :paid => true,
  #     (OPTIONAL - univ_dvd_rate) :univ_dvd_rate => XXX
  #     (OPTIONAL - univ only, defaults true)
  #                                :live => XXX
  #                                :lis => [ {:name => "foo1",
  #                                         :inStock => true,
  #     (OPTIONAL - queue_position)         :queue_position => XXX
  #     (OPTIONAL - dateOut)                :dateOut => XXX
  #     (OPTIONAL - dateBack)               :dateBack => YYY} ... ]
  #     (OPTIONAL - payments)      :payments => [ { :date=> X, :complete => true, :successful => true },
  #                                               { :date=> X, :complete => true, :successful => true } ]
  #                            },
  #                 :order2 => { ...  }  },
  #   :cust2 => ...
  # 
  # }
  #
  # After setup you can recover products, copies, lineitems, and customers with
  #    cust  = txt2cust("cust1")
  #    copy  = txt2co(  "foo1")
  #    product = txt2tit( "foo1")
  #    li    = txt2li(  "foo1")
  #    
  #  NOTE: if you specify the same server_name for in_field items, and/or orders,
  #        smartflix items will be created as multiple orders, but university items
  #        will be appended as larger orders (within each university, of course!) 
  #
  #  NOTE: the each cust can have 0 or more orders, but the symbol
  #  'in_field' is magical, and is handled differently: you don't get
  #  to specify products, university names, etc.
  #  
  #
  def build_fake(input)
    customers = []
    
    Vendor.create!(:name => "vendor1.com", :vendor_mood => VendorMood.create!(:moodText => "good")) unless Vendor.count > 0 
    vendor = Vendor.find(:first)
    
    input.keys.each do |cust_name|
      # break up the hash a bit
      customer_data = input[cust_name]
      in_field_data = customer_data[:in_field]
      unfilled_order_names = customer_data.keys.reject {|kk| kk == :in_field }
      
      # create customer
      billing_addr = Address.test_billing_addr
      billing_addr.save!
      shipping_addr = Address.test_shipping_addr
      shipping_addr.save!
      hh = {:email => "#{cust_name}_FAKE@smartflix.com"}
      hh[:password] = "abcdef" 
      cust = Customer.create!(hh)
      
      cust.shipping_address_id = shipping_addr.id
      cust.billing_address_id = billing_addr.id
      cust.save!
      
      customers << cust
      cat = Category.create!(:description => "cat", :parent_id => 0)
      
      # create orders, line_items, payments, copies, etc.
      build_unfilled_orders(cust, vendor, cat, customer_data, unfilled_order_names)
      build_infield_data(cust, vendor, cat, customer_data, in_field_data)
    end
    customers
  end

  def util_do_univ_charge
    # In our processing, we sort previous payments by timestamp, to see which is the most
    # recent.  If we don't sleep at least 1 second between univ charges, then the most_recent 
    # function won't work.
    sleep(1)

    verbose = false

    OverdueEngine.logger = lambda { |input| }
    OverdueEngine.logger = lambda { |input| puts input } if verbose
    OverdueEngine.bill_univ_students
  end


  
  def txt2tit(txt)
    Product.find_by_name(txt)
  end
  
  def txt2co(txt)
    Product.find_by_name(txt).copies.first
  end
  
  def txt2li(txt)
    Product.find_by_name(txt).line_items.first
  end
  
  def txt2cust(txt)
    Customer.find_by_email("#{txt.to_s}_FAKE@smartflix.com")
  end
  
  # This func will build zero or more products, copies, lis
  #
  # This does not allow full generality.  
  #
  # Input is of the form
  # 
  # { :product_1 => { :in_field => { 3 , 5 }, # 2 good copies in the field,
  #                                           # out 3 days and 5 days respectively
  #                   :good_copies  => 2,     # 2 more good copies in stock
  #                   :bad_copies   => 3,     # 3 bad copies in stock
  #                                           # and a bunch of unfilled LIs
  #                   :lis => [ <date>, <date>, [ <date>, :uni ], ],
  #
  #   :product_2 => { :in_field => { 3 , 5 },
  #                   :good_copies  => 2,
  #                   :bad_copies   => 2,
  #                   :lis => [ <date>, <date>, [ <date>, :uni ], ],
  # }
  #
  # After setup you can recover products, copies, lineitems, and customers with
  #    cust  = txt2cust("cust1")
  #    copy  = txt2co(  "foo1")
  #    product = txt2tit( "foo1")
  #    li    = txt2li(  "foo1")
  #    
  
  def build_fake_products(input)
    
    cat = Category.create!(:description => "cat", :parent_id => 0)
    univ = University.create!(:name => "univ", :subscription_charge => 20.0)
    vendor = Vendor.create!(:name => "fred.com", :vendor_mood_id => 2, :outOfBusinessP => false)
    author = Author.create!(:name => "Alpha Alpha")
    products = []
    
    input.each_pair do |product_name, val|
      product = Product.create!(:name => product_name.to_s,
                                :description => "foo",
                                :date_added => Date.today,
                                :author => author,
                                :vendor => vendor,
                                :categories => [cat],
                                :price => 9.99,
                                :date_added => Date.today - 200,
                                :purchase_price => 49.99)
      
      products << product
      
      val[:in_field].each do |days_out|
        before = (Date.today - days_out)
        
        copy = Copy.create!(:product => product,
                            :birthDATE => before,
                            :inStock => false,
                            :status => 1)
        
        shipment = Shipment.create!(:dateOut => before,
                                    :time_out => before.to_time)
        
        create_li_order_cust(product, :copy => copy, :shipment => shipment)   
        
      end
      
      val[:good_copies].times { Copy.create!(:product => product,
                                             :birthDATE => (Date.today - 365),
                                             :status => 1)}
      val[:bad_copies].times { Copy.create!(:product => product, 
                                            :birthDATE => (Date.today - 365),
                                            :status => 0) }
      val[:lis].each do |li_spec|
        li_date = li_univ = nil
        if li_spec.is_a?(Array)
          li_date = li_spec[0]
          li_univ = li_spec[1] ? univ : nil
        else
          li_date = li_spec
        end
        
        create_li_order_cust(product, :li_date => li_date, :univ => li_univ)
        
        # if a dvd is in a university, throw a bunch of other
        # unshipped LIs into the univ too - the algorithm to compute
        # delays counts unshipped university LIs if there are 6 or
        # less unshipped univ LIs (bc we're down to the bottom of the
        # barrel), but ignores univ LIs otherwise.
        if li_univ
          8.times do
            product = Product.create!(:name => String.rand,
                                      :description => "foo",
                                      :date_added => Date.today,
                                      :author => author,
                                      :vendor => vendor,
                                      :categories => [cat],
                                      :price => 9.99,
                                      :purchase_price => 49.99)
            create_li_order_cust(product, :li_date => li_date, :univ => li_univ)
          end
        end
        
      end
      
    end
    
    products
  end
  
  def create_li_order_cust(product, options)
    allowed = [:copy, :shipment, :li_date, :univ]
    raise "illegal options" if (options.keys - allowed).any?
    options[:li_date] ||= (Date.today - 365) 
    
    cust = Customer.create!(:email => "#{String.rand}_FAKE@smartflix.com", 
                            :password => "foobar",
                            :created_at => Time.now)
    order = Order.create!( # :university_id => university_id,
                          :customer => cust,
                          :orderDate => options[:li_date],
                          :server_name => "smartflix.com",
                          :university => options[:univ])
    
    li = LineItem.create!(:product => product,
                          :order => order,
                          :copy => options[:copy],
                          :shipment => options[:shipment],
                          :actionable => options[:actionable].nil? ? true : options[:actionable]  )
  end
  
  
  
end

class ActionController::TestCase
  def response_to_chrome(ret)
    if ret.is_a?(String)
      ret = ret
    else
      ret = ret.body
    end
    open("/tmp/zzz.html", "w") { |f| f << ret }
    system("chrome file:///tmp/zzz.html")
  end
end

class ActionController::Integration::Session
  
  def util_login(username, pwd)
    get "customer/login"
    request_via_redirect(:post, "/customer/login", { :email => username, :password => pwd})
  end
  
  def util_add_item_to_cart(product)
    request_via_redirect(:post, "/cart/add", :id=>product.product_id)
  end

  def util_add_item_to_wishlist(product)
    request_via_redirect(:post, "/cart/add_saved", :id=>product.product_id)
  end

  
  def util_checkout_from_cart(verify = false, expected_template = "cart/checkout")
    request_via_redirect(:get, "/cart/checkout")
    assert_template expected_template    if verify 
  end
  
  def util_create_new_customer(options)
    defaults = { :country_id => 223,
      :notifications => 1}
    
    options = defaults.merge(options)
    options.allowed_and_required( [:notifications, :country_id, :pwd, :email, :name_first, :name_last, :addr_1, :addr_2, :city, :state_id, :zip], [])
    
    request_via_redirect(:post, "/customer/new_customer", 
                         { "customer"=>{
                             "password_confirmation"=>options[:pwd],
                             "password"=>options[:pwd], 
                             "email"=>options[:email]},
                           "email_notifications"=>options[:notifications], 
                           "address"=>{ 
                             "first_name"=>options[:name_first],
                             "last_name"=>options[:name_last],
                             "address_1"=>options[:addr_1],
                             "address_2"=>options[:addr_2],
                             "city"=>options[:city],
                             "state_id"=>options[:state_id],
                             "postcode"=>options[:zip],
                             "country_id"=>options[:country_id]}
                         } )
  end

  def util_add_cc(options = {} )
    defaults = {
      :number => "5424000000000015",
      :month => Date.today.month,
      :year => Date.today.year + 1
    }
    
    options = defaults.merge(options)
    options.allowed_and_required( [:number, :month, :year], [])
    
    
    request_via_redirect(:post, "/customer/manage_cc", 
                         { "card_choice_credit_card_new"=>1, 
                           "credit_card_new"=>{ 
                             "number"=>options[:number],
                             "month"=>options[:month],
                             "year"=>options[:year]}
                         } )
  end
  
  def util_place_order(options = {} )
    
    defaults = { :terms_and_cond => true,
      :expect_success => true,
      :apply_credit => false,
      :use_stored_cc => false
    }

    options = defaults.merge(options)
    options.allowed_and_required( [:use_stored_cc, :cc_num, :cc_month, :cc_year, :terms_and_cond, :expect_success, :apply_credit], [])
    
    ret =    request_via_redirect(:post, "/cart/checkout", 
                  {"terms_and_conditions"=> (options[:terms_and_conditions] ? "1" : "0"),
                    "apply_credit"=> (options[:terms_and_conditions] ? "1" : "0"),
                    "credit_card"=>{
                      "number"=>options[:cc_num],
                      "month"=>options[:cc_month],
                      "year"=>options[:cc_year]}
                  } )

    # response_to_firefox
    
    if options[:expect_success] == true
      assert_template "cart/order_success"
    elsif options[:expect_success] == false
      assert_template "cart/checkout"
    else
      # do nothing
    end

    return @response
  end
  
  def response_to_firefox()
    open("/tmp/zzz.html", "w") { |f| f << @response.body }
    system("firefox file:///tmp/zzz.html")
  end

  
end
  
# Set up a logger object, since some things we test need it
LOGGER = Logger.new(STDOUT)

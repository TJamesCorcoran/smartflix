
require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
class CartController; def rescue_action(e) raise e end; end

class CartControllerTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  # Utility methods for getting cart
  def get_customer_cart
    Customer.find(session[:customer_id]).cart
  end
  def get_anonymous_cart
    Cart.find_by_cart_id(session[:anonymous_cart_id])
  end

  def add_to_customer_cart_save_for_later(product)
    cart = get_customer_cart 

    ci = CartItem.for_product(product)
    ci.saved_for_later = true
    cart.cart_items << ci

    cart.save!
  end


  def setup
    @controller = CartController.new
    @request    = ActionController::TestRequest.new
    @request.instance_eval do
      def host
        self.env['HTTP_HOST']
      end
    end
    @request.env['HTTP_HOST'] = 'smartflix.com'
    @response   = ActionController::TestResponse.new
  end

  def setup_customer
    state = State.create!(:name => "Foobaristan", :code => "FO")
    customer = Customer.create!(:password => "password", :email =>"test@smartflix.com", :first_name => "first", :last_name => "last")
    customer.billing_address = BillingAddress.create!(:first_name => "first",
                                                :last_name => "last",
                                                :address_1 => "addr1",
                                                :address_2 => "addr2",
                                                :city => "city",
                                                :state_id => state.id,
                                                :postcode =>"02474",
                                                :country_id => 223)
    customer.shipping_address = ShippingAddress.create!(:first_name => "first",
                                                    :last_name => "last",
                                                    :address_1 => "addr1",
                                                    :address_2 => "addr2",
                                                    :city => "city",
                                                    :state_id => state.id,
                                                    :postcode =>"02474",
                                                    :country_id => 223)
    customer.save

    cc =  CreditCard.secure_setup( { :number => '4111111111111111', :month => 12, :year => 2020, :customer => customer, :type=>"master"}, customer)
    cc.save

    customer
  end

  # Index doesn't do much testable, should return success
  def test_index                      
    get :index
    assert_response :success
    assert_template 'index'
  end

  ########################################################
  # Cart manipulation, anonymous user
  ########################################################

  # Make sure adding a product to the cart works
  def test_add_product                      
    post :add, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_anonymous_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(1, cart.cart_items.first.product.id)
  end

  # Make sure that using a get does not add a product
#   def test_add_product_get                      
#     get :index
#     get :add, :id => 1
#     assert_redirected_to :controller => :cart,  :action => ''
#     cart = get_anonymous_cart
#     assert_equal(0, cart.cart_items.size)
#   end

  # Make sure we can add a set of products to the cart
  def test_add_set                      
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_anonymous_cart
    assert_equal(2, cart.cart_items.size)
    assert_equal(5, cart.cart_items.first.product.id)
    assert_equal(4, cart.cart_items.last.product.id)
  end

#   # Again for sets, make sure that using get does not add to cart
#   def test_add_set_get                      
#     get :index
#     get :add_set, :id => 1
#     assert_redirected_to :controller => :cart,  :action => ''
#     cart = get_anonymous_cart
#     assert_equal(0, cart.cart_items.size)
#   end

  # Make sure we can add a bundle of products to the cart
  def test_add_bundle                      
    post :add_bundle, :id => 2
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_anonymous_cart
    assert_equal(4, cart.cart_items.size)
    assert_equal(2, cart.cart_items[0].product.id)
    assert_equal(3, cart.cart_items[1].product.id)
    assert_equal(4, cart.cart_items[2].product.id)
    assert_equal(5, cart.cart_items[3].product.id)
  end

  # Make sure saving for later works
  def test_save_for_later                      
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart, :action => ''
    post :move, :id => 4
    cart = get_anonymous_cart
    assert_equal(2, cart.cart_items.size)
    assert_equal(5, cart.cart_items.first.product.id)
    assert_equal(4, cart.cart_items.last.product.id)
    assert_equal(1, cart.items_to_buy.size)
    assert_equal(5, cart.items_to_buy.first.product.id)
    assert_equal(1, cart.items_saved.size)
    assert_equal(4, cart.items_saved.first.product.id)
  end

  # Make sure deleting works
  def test_delete                      
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart, :action => ''
    post :delete, :id => 5
    cart = get_anonymous_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(4, cart.cart_items.first.product.id)
  end

  ########################################################
  # Cart manipulation, logged in customer
  ########################################################

  # Make sure adding a product to the cart works
  def test_add_product_logged_in                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    post :add, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_customer_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(1, cart.cart_items.first.product.id)
  end

  # Make sure we can add a set of products to the cart
  def test_add_set_logged_in                  
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_customer_cart
    assert_equal(2, cart.cart_items.size)
    assert_equal(cart.cart_items.map(&:product_id).sort, [4,5])
  end

  # Make sure we can add a bundle of products to the cart
  def test_add_bundle_logged_in                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    cart = get_customer_cart
    post :add_bundle, :id => 2
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_customer_cart

    assert_equal(4, cart.cart_items.size)
    assert_equal(2, cart.cart_items[0].product.id)
    assert_equal(3, cart.cart_items[1].product.id)
    assert_equal(4, cart.cart_items[2].product.id)
    assert_equal(5, cart.cart_items[3].product.id)
  end

  # Make sure saving for later works
  def test_save_for_later_logged_in                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    post :move, :id => 4
    cart = get_customer_cart
    assert_equal(2, cart.cart_items.size)
    assert_equal(cart.cart_items.map(&:product_id).sort, [4,5])

    assert_equal(1, cart.items_to_buy.size)
    assert_equal(5, cart.items_to_buy.first.product.id)

    assert_equal(1, cart.items_saved.size)
    assert_equal(4, cart.items_saved.first.product.id)
    # check that adding the set restores the saved item to
    # "item_to_buy" status
    post :add_set, :id => 1
    cart = get_customer_cart
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(0, cart.items_saved.size)
    # check that adding the individual item restores the saved item to
    # "item_to_buy" status
    post :move, :id => 4
    post :add, :id => 4
    cart = get_customer_cart
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(0, cart.items_saved.size)
  end

  # Make sure deleting works
  def test_delete_logged_in                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    post :delete, :id => 5
    cart = get_customer_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(4, cart.cart_items.first.product.id)
  end

  ########################################################
  # Cart merging across not logged in and logged in
  ########################################################

  # Make sure cart merging works as expected
  def test_merge_carts                      
    # Add to anonymous cart
    post :add, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    cart = get_anonymous_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(1, cart.cart_items.first.product.id)
    # Log in
    session[:customer_id] = 1
    get_customer_cart.empty!

    # Make sure customer cart now has right stuff
    get :index
    cart = get_customer_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(1, cart.cart_items.first.product.id)
    assert_nil(get_anonymous_cart)
  end

  ########################################################
  # Checkout
  ########################################################

  # Make sure simple checkout works and checks out right stuff
  def test_checkout_visa                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-1111", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
    assert_equal('smartflix.com', orders.first.server_name)
  end

  def test_checkout_mastercard                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '5424000000000015', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (MasterCard) XXXX-XXXX-XXXX-0015", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
  end

  def test_checkout_amex      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    ret = post :checkout, :credit_card => { :number => '370000000000002', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'



    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (AmericanExpress) XXXX-XXXX-XXXX-0002", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
  end

  def test_checkout_expired                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    ret = post :checkout, :credit_card => { :number => '370000000000002', :month => 12, :year => 2000 }, :terms_and_conditions => true
    assert_template 'checkout'
    assert ret.body.match(/Credit card expired/)
    
  end

  def test_checkout_empty                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    ret = post :checkout, :credit_card => { :number => '370000000000002', :month => 12, :year => 2000 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => ''
  end

  def test_checkout_bad_card                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    ret =    post :checkout, :credit_card => { :number => '4222222222222', :month => 12, :year => 2010 }, :terms_and_conditions => true
    assert_template 'checkout'
    assert ret.body.match(/credit card charge failed/)
  end

  ########################################################
  # Checkout visiting via a cobranded URL
  ########################################################

  # Make sure simple checkout works and checks out right stuff
  def test_checkout_cobranded                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    @request.env['HTTP_HOST'] = 'woodturningonline.smartflix.com'
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-1111", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
    assert_equal('woodturningonline.smartflix.com', orders.first.server_name)
  end

  ########################################################
  # Make sure non-merging checkout works as expected
  ########################################################

  def test_non_merge_checkout                      
    # Log in and add to cart
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add, :id => 1
    # Log out and add to anonymous cart
    session[:customer_id] = nil
    post :add, :id => 2
    cart = get_anonymous_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(2, cart.cart_items.first.product.id)
    # Log back in and checkout, without going to cart first, making sure we only check out anonymous cart
    session[:customer_id] = 1

    session[:timestamp] = Time.now.to_i
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    assert_equal(3, Customer.find(1).orders.size)
    assert_equal(1, Customer.find(1).orders.first.line_items.size)
    assert_equal(2, Customer.find(1).orders.first.line_items.first.product.id)
    # Make the customer cart still contains the right video (the non-merged one)
    cart = get_customer_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(1, cart.cart_items.first.product.id)
  end

  ########################################################
  # Use a coupon when checking out
  ########################################################

  def test_coupon_checkout                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    post :claim_code, :code => 'LE_COOP'
    assert_redirected_to :controller => :cart,  :action => 'checkout'
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-1111", orders.first.payments.last.payment_method)
    assert_in_delta(22.43, orders.first.payments.last.amount.to_f, 0.001)
    assert_in_delta(22.43, orders.first.payments.last.amount_as_new_revenue.to_f, 0.001)
  end

  ########################################################
  # Use a gift certificate when checking out
  ########################################################

  def test_gc_checkout                      
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(BigDecimal('0.00'), Customer.find(1).credit)
    post :claim_code, :code => 'LE_GIFT'
    assert_redirected_to :controller => :cart,  :action => 'checkout'
    assert_equal(BigDecimal('1.33'), Customer.find(1).credit)
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 },
                    :terms_and_conditions => true, :apply_credit => true
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Gift Certificate / Credit Card (Visa) XXXX-XXXX-XXXX-1111", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
    assert_equal(BigDecimal('22.65'), orders.first.payments.last.amount_as_new_revenue)
  end

  ########################################################
  # Use a UNIVERSITY gift certificate when checking out
  ########################################################

  def helper_univ_gc_checkout(options)

    options.allowed_and_required([:gc_code, 
                                  :product_id,
                                  :apply_credit,
                                  :apply_month_credit,
                                  :pre_checkout_credit,
                                  :pre_checkout_months, 
                                  :post_checkout_credit,
                                  :post_checkout_months, 
                                  :product_ids_in_lis,
                                  :payment_type,
                                  :payment_total,
                                  :payment_as_new_revenue])
    get :index
    session[:customer_id] = 1
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    
    # setup GC
    assert_equal(0.00, Customer.find(1).credit.to_f)
    assert_equal(0, Customer.find(1).credit_months)

    post :claim_code, :code => options[:gc_code]
    assert_redirected_to :controller => :cart,  :action => 'checkout'

    assert_equal(options[:pre_checkout_credit], Customer.find(1).credit.to_f)
    assert_equal(options[:pre_checkout_months], Customer.find(1).credit_months)

    # put item in cart
    post :add, :id => options[:product_id]
    assert_redirected_to :controller => :cart,  :action => ''

    # do checkout
    num_orders =Customer.find(1).orders.size
    post( :checkout, 
          :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 },
          :terms_and_conditions => true, 
          :apply_credit => options[:apply_credit],
          :apply_month_credit => options[:apply_month_credit])
    assert_redirected_to :controller => :cart,  :action => 'order_success'

    valid_orders = Customer.find(1).orders
#    valid_orders = Customer.find(1).orders.select { |o| o.line_items.size > 0 }
    new_order = valid_orders.max_by(&:order_id)

    assert_equal(num_orders + 1, Customer.find(1).orders.select { |o| o.line_items.size > 0 }.size) # 1 more order


    assert_equal(options[:product_ids_in_lis].size, new_order.line_items.size)
    assert_equal(options[:product_ids_in_lis].to_set, new_order.line_items.map{|li| li.product.id}.to_set)

    
    assert_equal(options[:payment_type], new_order.payments.last.payment_method)
    assert_equal(options[:payment_total].to_d, new_order.payments.last.amount)

    assert_equal(options[:payment_as_new_revenue].to_d, new_order.payments.last.amount_as_new_revenue)

    assert_equal(options[:post_checkout_credit].to_f, Customer.find(1).credit)
    assert_equal(options[:post_checkout_months], Customer.find(1).credit_months)

  end

#   deprecated, bc unis are now free in the first month, and we don't use uni months
#   def test_univ_gc_checkout_months            
#     # use a 'months' gift cert
#     helper_univ_gc_checkout({:gc_code                  => 'UNIV_GIFT', 
#                               :product_id              => products(:product_univstub_2).id ,
#                               :apply_credit            => false,
#                               :apply_month_credit      => true,
#                               :pre_checkout_credit     => 0.00,
#                               :pre_checkout_months     => 2, 
#                               :post_checkout_credit    => 0.00,
#                               :post_checkout_months    => 1, 
#                               :product_ids_in_lis      => products(:product_univstub_2).university.products.map(&:id),
#                               :payment_type            => "Gift Certificate",
#                               :payment_total           => 22.95,
#                               :payment_as_new_revenue  => 0.00
#                             })
#   end

#   def test_univ_gc_checkout_months_unused            
#     # have a 'months' gift cert, but don't use it
#     helper_univ_gc_checkout({:gc_code                  => 'UNIV_GIFT', 
#                               :product_id              => products(:product_univstub_2).id ,
#                               :apply_credit            => false,
#                               :apply_month_credit      => false,
#                               :pre_checkout_credit     => 0.00,
#                               :pre_checkout_months     => 2, 
#                               :post_checkout_credit    => 0.00,
#                               :post_checkout_months    => 2, 
#                               :product_ids_in_lis      => products(:product_univstub_2).university.products.map(&:id),
#                               :payment_type            => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
#                               :payment_total           => 22.95,
#                               :payment_as_new_revenue  => 22.95
#                             })
#   end

#   def test_univ_gc_checkout_dollars                      
#     # use a 'dollars' gift cert
#     helper_univ_gc_checkout({:gc_code                  => 'DOLLARS_GIFT', 
#                               :product_id              => products(:product_univstub_2).id ,
#                               :apply_credit            => true,
#                               :apply_month_credit      => false,
#                               :pre_checkout_credit     => 30.00,
#                               :pre_checkout_months     => 0, 
#                               :post_checkout_credit    => 7.05,
#                               :post_checkout_months    => 0, 
#                               :product_ids_in_lis      => products(:product_univstub_2).university.products.map(&:id),
#                               :payment_type            => "Gift Certificate",
#                               :payment_total           => 22.95,
#                               :payment_as_new_revenue  => 0.00
#                             })
#   end

#   def test_univ_gc_checkout_dollars_unused            
#     # have a 'dollars' gift cert, but don't use it
#     helper_univ_gc_checkout({:gc_code                  => 'DOLLARS_GIFT', 
#                               :product_id              => products(:product_univstub_2).id ,
#                               :apply_credit            => false,
#                               :apply_month_credit      => false,
#                               :pre_checkout_credit     => 30.00,
#                               :pre_checkout_months     => 0, 
#                               :post_checkout_credit    => 30.00,
#                               :post_checkout_months    => 0, 
#                               :product_ids_in_lis      => products(:product_univstub_2).university.products.map(&:id),
#                               :payment_type            => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
#                               :payment_total           => 0.01,
#                               :payment_as_new_revenue  => 0.01
#                             })
#   end

  def test_univ_gc_checkout_dollars  
    # at checkout, check box to draw down dollars.  Do so.
    helper_univ_gc_checkout({:gc_code                  => 'DOLLARS_GIFT', 
                              :product_id              => products(:product_univstub_2).id ,
                              :apply_credit            => true,
                              :apply_month_credit      => false,
                              :pre_checkout_credit     => 30.00,
                              :pre_checkout_months     => 0, 
                              :post_checkout_credit    => 30.00,
                              :post_checkout_months    => 0, 
                              :product_ids_in_lis      => products(:product_univstub_2).university.products.map(&:id),
                              :payment_type            =>  "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                              :payment_total           => 0.01,
                              :payment_as_new_revenue  => 0.01
                            })
  end


  ########################################################
  # Test checkout using a token as a login credential
  ########################################################

  # Make sure simple checkout works and checks out right stuff
  def test_checkout_token            
    token = OnepageAuthToken.create_token(Customer.find(1), 3, :controller => 'cart', :action => 'checkout')
    get :add_set, :id => 1, :token => token
    assert_redirected_to :controller => :cart, :action => 'checkout', :token => token
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 },
                    :terms_and_conditions => true, :token => token
    assert_redirected_to :controller => :cart,  :action => 'order_success'
    orders = Customer.find(1).orders
    assert_equal(3, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-1111", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
  end



  def test_checkout_token_partial_customer                      
    cust = Customer.create(:email => "123@smartflix.com",
                             :password => "12345",
                             :password_confirmation => "12345",
                             :arrived_via_email_capture => 1,
                             :first_ip_addr => "127.0.0.1",
                             :first_server_name => "smartflix.com")

    token = OnepageAuthToken.create_token(cust, 3, :controller => 'cart', :action => 'checkout')
    get :add_set, :id => 1, :token => token
    post :checkout, :token => token
    assert_redirected_to :controller => :customer, :action => 'login'

  end


  # XXXFIX P2: Test error conditions, ie checkout without a cc number

  ########################################################
  # Checkout redux (STORED version)
  ########################################################

  # Make sure simple checkout works and checks out right stuff
  def test_checkout_stored                    
    get :index
    session[:customer_id] = 3
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart,  :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true
    assert_redirected_to :controller => :cart, :action => 'order_success'
    orders = Customer.find(session[:customer_id]).orders
    assert_equal(1, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-0027", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
    assert_equal('smartflix.com', orders.first.server_name)
  end

  def test_checkout_stored_expired_cc                      
    # setup a customer with 1 credit card, and make it expired.
    customer = setup_customer()
    customer.credit_cards.first.update_attributes(:year => (Date.today.year - 1))

    # add an item to the cart
    get :index
    session[:customer_id] = customer.id
    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1

    # go to the checkout page ; make sure that you do ** NOT ** get the option of using an expired card
    ret = get :checkout
    assert_template "checkout"
    assert ret.body.match(/Use Visa ending in/).nil?
    
    # try to use it anyway; make sure that we get yelled at (and we don't blow up)
    ret =    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true
    assert_template "checkout"
    assert ret.body.match(/Error: Credit card expired|Error: No valid stored credit card/)
  end


  ########################################################
  # Checkout visiting via a cobranded URL
  ########################################################

  # Make sure simple checkout works and checks out right stuff
  def test_checkout_stored_cobranded                      
    get :index
    session[:customer_id] = 3
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    @request.env['HTTP_HOST'] = 'woodturningonline.smartflix.com'
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart, :action => ''
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true
    assert_redirected_to :controller => :cart, :action => 'order_success'
    orders = Customer.find(3).orders
    assert_equal(1, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-0027", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
    assert_equal('woodturningonline.smartflix.com', orders.first.server_name)
  end

  ########################################################
  # Make sure non-merging checkout works as expected
  ########################################################

  def test_non_merge_checkout_stored                      
    # Log in and add to cart
    get :index
    session[:customer_id] = 3
    session[:timestamp] = Time.now.to_i
    post :add, :id => 1
    # Log out and add to anonymous cart
    session[:customer_id] = nil
    post :add, :id => 2
    cart = get_anonymous_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(2, cart.cart_items.first.product.id)
    # Log back in and checkout, without going to cart first, making sure we only check out anonymous cart
    session[:customer_id] = 3
    session[:timestamp] = Time.now.to_i
    assert_equal(0, Customer.find(3).orders.size)
    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true
    assert_redirected_to :controller => :cart, :action => 'order_success'
    assert_equal(1, Customer.find(3).orders.size)
    assert_equal(1, Customer.find(3).orders.first.line_items.size)
    assert_equal(2, Customer.find(3).orders.first.line_items.first.product.id)
    # Make the customer cart still contains the right video (the non-merged one)
    cart = get_customer_cart
    assert_equal(1, cart.cart_items.size)
    assert_equal(1, cart.cart_items.first.product.id)
  end

  ########################################################
  # Use a coupon when checking out
  ########################################################

  def test_coupon_checkout_stored                      
    get :index
    session[:customer_id] = 3
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart, :action => ''
    post :claim_code, :code => 'LE_COOP'
    assert_redirected_to :controller => :cart, :action => 'checkout'
    assert_equal(0, Customer.find(3).orders.size)
    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true
    assert_redirected_to :controller => :cart, :action => 'order_success'
    orders = Customer.find(3).orders
    assert_equal(1, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-0027", orders.first.payments.last.payment_method)

    assert_in_delta(22.43, orders.first.payments.last.amount.to_f, 0.001)
    assert_in_delta(22.43, orders.first.payments.last.amount_as_new_revenue.to_f, 0.001)
  end

  ########################################################
  # Use a gift certificate when checking out
  ########################################################

  def test_gc_checkout_stored                      
    get :index
    session[:customer_id] = 3
    get_customer_cart.empty!

    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    assert_redirected_to :controller => :cart, :action => ''
    assert_equal(BigDecimal('0.00'), Customer.find(3).credit)
    post :claim_code, :code => 'LE_GIFT'
    assert_redirected_to :controller => :cart, :action => 'checkout'
    assert_equal(BigDecimal('1.33'), Customer.find(3).credit)
    assert_equal(2, Customer.find(1).orders.size)
    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true, :apply_credit => true
    assert_redirected_to :controller => :cart, :action => 'order_success'
    orders = Customer.find(3).orders
    assert_equal(1, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Gift Certificate / Credit Card (Visa) XXXX-XXXX-XXXX-0027", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
    assert_equal(BigDecimal('22.65'), orders.first.payments.last.amount_as_new_revenue)
  end

  ########################################################
  # Test checkout using a token as a login credential
  ########################################################

  # Make sure simple checkout works and checks out right stuff
  def test_checkout_stored_token                      
    token = OnepageAuthToken.create_token(Customer.find(3), 3, :controller => 'cart', :action => 'checkout')
    get :add_set, :id => 1, :token => token
    assert_redirected_to :controller => :cart, :action => 'checkout', :token => token
    assert_equal(0, Customer.find(3).orders.size)
    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true, :token => token
    assert_redirected_to :controller => :cart, :action => 'order_success'
    orders = Customer.find(3).orders
    assert_equal(1, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(5, orders.first.line_items.first.product.id)
    assert_equal(4, orders.first.line_items.last.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-0027", orders.first.payments.last.payment_method)
    assert_equal(BigDecimal('23.98'), orders.first.payments.last.amount)
  end

  ##################################################################
  # Test quick wishlist checkout action part of the email promotion
  # offering discounts to customers who buy stuff from their wish
  # list.
  ##################################################################

  def test_quick_discount_checkout_action                      
    title_id = 1
    discount_amount = BigDecimal("2.0")

    # token1 is the token sent out in the user promotional email
    token1 = OnepageAuthToken.create_token(Customer.find(3), 3, :controller => 'cart', :action => 'quick_discount', :id => title_id)
    # token2 identical to that which will be generated by the quick_discount:
    token2 = OnepageAuthToken.create_token(Customer.find(3), 3, :controller => 'cart', :action => 'checkout')

    # quick_discount creates an anonymous cart, creates an order for
    # it populated with a new cart_item for the given title with a
    # discount applied, and then redirects to the checkout action.
    get :quick_discount, :id => title_id, :token => token1
    assert_redirected_to :controller => :cart, :action => 'checkout', :token => token2

    cart = get_anonymous_cart
    assert_equal(1, cart.cart_items.count)
    assert_equal(title_id, cart.cart_items.first.product.id)

    # verify the charge is discounted
    assert_equal(discount_amount, cart.cart_items.first.discount)
    discounted_total = cart.cart_items.first.product.price-discount_amount
    assert_equal(discounted_total, cart.total)
    get :checkout, :token => token2
    assert_response :success
    #                                             1234567890123456
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 },
                    :terms_and_conditions => true, :token => token2
    assert_redirected_to :controller => :cart, :action => 'order_success'

    orders = Customer.find(3).orders
    assert_equal(1, orders.size)
    assert_equal(1, orders.first.line_items.size)
    assert_equal(title_id, orders.first.line_items.first.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-1111", orders.first.payments.last.payment_method)
    assert_equal(discounted_total, orders.first.payments.last.amount)
  end


  # same as test_quick_discount_checkout_action, but using stored credit card
  def test_quick_discount_checkout_action_stored_cc                      
    title_id = 1
    discount_amount = BigDecimal("2.0")

    # token1 is the token sent out in the user promotional email
    token1 = OnepageAuthToken.create_token(Customer.find(3), 3, :controller => 'cart', :action => 'quick_discount', :id => title_id)
    # token2 identical to that which will be generated by the quick_discount:
    token2 = OnepageAuthToken.create_token(Customer.find(3), 3, :controller => 'cart', :action => 'checkout')

    get :quick_discount, :id => title_id, :token => token1
    assert_redirected_to :controller => :cart, :action => 'checkout', :token => token2

    cart = get_anonymous_cart

    # should only be 1 thing in the cart.
    assert_equal(1, cart.cart_items.count)
    assert_equal(title_id, cart.cart_items.first.product.id)

    # verify the cart item carries the discount.
    assert_equal(discount_amount, cart.cart_items.first.discount)

    discounted_total = cart.cart_items.first.product.price-discount_amount
    assert_equal(discounted_total, cart.total)

    get :checkout, :token => token2
    assert_response :success

    post :checkout, :payment_method => "use_last_stored_card", :terms_and_conditions => true, :token => token2
    assert_redirected_to :controller => :cart, :action => 'order_success'

    orders = Customer.find(3).orders
    assert_equal(1, orders.size)
    assert_equal(1, orders.first.line_items.size)
    assert_equal(title_id, orders.first.line_items.first.product.id)
    assert_equal("Credit Card (Visa) XXXX-XXXX-XXXX-0027", orders.first.payments.last.payment_method)
    assert_equal(discounted_total, orders.first.payments.last.amount)
  end

  # test that after checkout we get upsell offers
  def test_checkout_postcheckout_show                      
    customer = setup_customer()
    get :index
    session[:customer_id] = customer.id
    session[:timestamp] = Time.now.to_i
    post :add_set, :id => 1
    post :checkout, :credit_card => { :number => '4111111111111111', :month => 12, :year => 2020 }, :terms_and_conditions => true
    assert_redirected_to :controller => :cart, :action => 'order_success'

    # put some things in the customer's cart, and mark them as saved for later
    add_to_customer_cart_save_for_later(products(:product1))
    add_to_customer_cart_save_for_later(products(:product2))
    add_to_customer_cart_save_for_later(products(:product6))
    add_to_customer_cart_save_for_later(products(:product7))


    def first()
      # order success - the first two recos
      get :order_success
      assert_response :success
      assert_not_nil assigns['upsell_products']
      assert_not_nil assigns['upsell_products'][0]
      assert_not_nil assigns['upsell_products'][1]
      assert_equal products(:product1), assigns['upsell_products'][0]
      assert_equal products(:product2), assigns['upsell_products'][1]
    end

    def second()
      # post checkout page 2 - the next two recos
      get :postcheckout_show, :page => 2    
      assert_response :success
      assert_not_nil assigns['upsell_products']
      assert_not_nil assigns['upsell_products'][0]
      assert_not_nil assigns['upsell_products'][1]
      assert_equal products(:product6), assigns['upsell_products'][0]
      assert_equal products(:product7), assigns['upsell_products'][1]
    end

    first()
    second()
    first()
    second()

  end


  def test_checkout_oneclick_product                      
    customer = setup_customer()
    cart = Cart.create!(:customer_id => customer.id)
    ci_one = CartItem.for_product(products(:product1))
    ci_one.saved_for_later = true
    cart.cart_items << ci_one
    ci_two = CartItem.for_product(products(:product2))
    ci_two.saved_for_later = true
    cart.cart_items << ci_two    

    # pinging the oneclick_checkout_product url should create an order and
    # redirect us to postcheckout_show ...
    get :index
    session[:customer_id] = customer.id
    session[:timestamp] = Time.now.to_i


    post :oneclick_checkout_product, :id => products(:product3).id
    assert_redirected_to :controller => :cart, :action => 'postcheckout_show', :page => 1
    orders = customer.orders

    assert_equal(1, orders.size)
    assert_equal(1, orders.first.line_items.size)
    assert_equal(products(:product3).id, orders.first.line_items.first.product.id)


    # ...then pinging postcheckout_show should get us more recos
    #
    get :postcheckout_show, :page => 2
    assert_not_nil assigns(:page)
    assert_not_nil assigns(:final_page)
    assert_not_nil assigns(:upsell_products)

    assert_equal   2, assigns(:upsell_products).size
  end

  def test_checkout_oneclick_set                      
    customer = setup_customer()
    cart = Cart.create!(:customer_id => customer.id)

    get :index
    session[:customer_id] = customer.id
    session[:timestamp] = Time.now.to_i


    post :oneclick_checkout_set, :id => product_sets(:product_set1).id
    assert_redirected_to :controller => :cart, :action => 'postcheckout_show', :page => 1
    orders = customer.orders

    assert_equal(1, orders.size)
    assert_equal(2, orders.first.line_items.size)
    assert_equal(products(:product4).id, orders.first.line_items[1].product.id)
    assert_equal(products(:product5).id, orders.first.line_items[0].product.id)
  end

  def test_checkout_oneclick_univ    
    customer = setup_customer()
    cart = Cart.create!(:customer_id => customer.id)

    get :index
    session[:customer_id] = customer.id
    session[:timestamp] = Time.now.to_i

    post :oneclick_checkout_university, :id => universities(:foo_university).id
    assert_redirected_to :controller => :cart, :action => 'postcheckout_show', :page => 1
    orders = customer.orders

    assert_equal(1, orders.size)
    assert_equal(3, orders.first.line_items.size)

    assert_equal(orders.first.line_items.map(&:product_id).sort, 
                 [ products(:product1), products(:product2), products(:product3)].map(&:id).sort)
  end

  def test_univstub_with_account_credit
    verbose = false 
    
    [

     # one univ
     # * no account credit
     { :test_name => "one univ Visa",
       :ids => [ 100 ],
       :initial_account_credit =>0, 
       :order_count => 1,
       :ending_account_credit => 0.0,
       :payments => [ { :payment_method => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 0.01,
                        :amount_as_new_revenue => 0.01,
                        :complete => false,
                        :successful => false } ]
     },

     # one univ, one regular item
     # * 
     # * part of regular item on account credit
     { :test_name => "one univ, one regular",
       :ids => [ 1, 100 ],
       :initial_account_credit =>5, 
       :order_count => 2,
       :ending_account_credit => 0.0,
       :payments => [ { 
                        :payment_method => "Gift Certificate / Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 9.99,
                        :amount_as_new_revenue => 4.99,
                        :complete => false,
                        :successful => false },
                      { :payment_method => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 0.01,
                        :amount_as_new_revenue => 0.01,
                        :complete => false,
                        :successful => false } ]
     },

     # one univ, two regular items
     # * all of univ on account credit
     # * part of regular items on account credit
     { :test_name => "one univ, two regular",
       :ids => [ 1, 2, 100 ],
       :initial_account_credit =>10, 
       :order_count => 2,
       :ending_account_credit => 0,
       :payments => [ { :payment_method => "Gift Certificate / Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 19.98,
                        :amount_as_new_revenue => 9.98,
                        :complete => false,
                        :successful => false },
                      { :payment_method => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 0.01,
                        :amount_as_new_revenue => 0.01,
                        :complete => false,
                        :successful => false }
                    ]
     },

     # twos univ, one regular items
     # * all of univ #1 on account credit
     # * part of univ #2 on account credit
     # * all of regular items on account credit
     { :test_name => "two univs, one regular",
       :ids => [ 1, 100, 101 ],
       :initial_account_credit =>5, 
       :order_count => 3,
       :ending_account_credit => 0.0,
       :payments => [ # why not all gift cert?
                      # sigh...

                      # why does the next line say " ... / Gift Cert" ?  Because
                      # of a weirdness where we calculate wether we're using gift certs
                      # before we peel off the univ stubs.  Sigh.
                      { :payment_method => "Gift Certificate / Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 9.99,
                        :amount_as_new_revenue => 4.99,
                        :complete => false,
                        :successful => false },
                     { :payment_method => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 0.01,
                        :amount_as_new_revenue => 0.01,
                        :complete => false,
                        :successful => false },
                      { :payment_method => "Credit Card (Visa) XXXX-XXXX-XXXX-1111",
                        :amount => 0.01,
                        :amount_as_new_revenue => 0.01,
                        :complete => false,
                        :successful => false }
                    ]
     }

     
     
    ].each do |test_case|
      
      puts "========== #{test_case[:test_name]}" if verbose

      CreditCard.destroy_all
      Customer.destroy_all
      customer = setup_customer()

      customer.add_account_credit(test_case[:initial_account_credit])
      customer.save

      get :index
      session[:customer_id] = customer.id
      session[:timestamp] = Time.now.to_i
      
      test_case[:ids].each { |id|         post :add, :id => id      }
      
      post :checkout, :payment_method => "use_last_stored_card", 
      :terms_and_conditions => true,
      :apply_credit => true
      
      assert_redirected_to :controller => :cart, :action => 'order_success'

      assert_equal(test_case[:order_count], customer.reload.orders.size)
      assert_equal(test_case[:ending_account_credit], customer.account_credit.amount.to_f)
      
      payment_index = 0
      customer.reload.orders.map { |o| o.payments.first}.zip(test_case[:payments]) do |actual, gold|
        x=  actual.order # very weird ; if we reference actual.order, the test passes; if we don't, one test fails.  Caching?  Virtual machine bug?
        if verbose
          puts "----------"
          puts "order: univ_id: #{actual.order.university_id}"
          puts "actual: #{actual.inspect}"
          puts "gold: #{gold.inspect}"
        end
        assert_equal(gold[:payment_method], actual.send(:payment_method), "**** in '#{test_case[:test_name]}', payment_index #{payment_index}")
        assert_equal(gold[:complete], actual.send(:complete), "expected complete == #{gold[:complete]}, got #{actual.send(:complete)}" )
        assert_equal(gold[:successful], actual.send(:successful), "expected successful == #{gold[:successful]}, got #{actual.send(:successful)}")
        assert_in_delta(gold[:amount], actual.send(:amount).to_f, 0.001, "expected amount == #{gold[:amount]}, got #{actual.send(:amount)}")
        assert_in_delta(gold[:amount_as_new_revenue], actual.send(:amount_as_new_revenue).to_f, 0.001, "expected amount_as_new_revenue == #{gold[:amount_as_new_revenue]}, got #{actual.send(:amount_as_new_revenue)}")
        payment_index += 1
      end
      
    end
  end

end

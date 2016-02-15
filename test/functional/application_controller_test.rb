
require File.dirname(__FILE__) + '/../test_helper'
# require 'application'

# Re-raise errors caught by the controller.
# class ApplicationController; def rescue_action(e) raise e end; end

class ApplicationControllerTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  def setup
    @controller = ApplicationController.new
    @request    = ActionController::TestRequest.new
    @request.instance_eval do
      def host
        self.env['HTTP_HOST']
      end
    end
    @request.env['HTTP_HOST'] = 'smartflix.com'
    @response   = ActionController::TestResponse.new

    get :zot
    session[:customer_id] = 1
  end

  def teardown
    customer.cart.andand.destroy
    customer.account_credit.andand.destroy
    session[:first_request] = nil  # store_controller_test wants to think that it's the first one here
  end


  # Utility methods 
  def customer()    Customer.find(session[:customer_id])  end
  def cart()       
    customer.carts << Cart.create!(:customer_id => customer.id) unless customer.cart
    customer.carts[0]
  end

  def add_to_customer_cart_regular(product)
    ci = CartItem.for_product(product)
    cart.cart_items << ci
    cart.save!
  end

  def add_to_customer_cart_save_for_later(product)
    ci = CartItem.for_product(product)
    ci.saved_for_later = true
    cart.cart_items << ci
    cart.save!
  end

  def can_use_credit_test(product,
                          dollars, months, 
                          expected_use_credit, expected_use_months)
    customer.cart.andand.destroy
    customer.account_credit.andand.destroy #.update_attributes(:univ_months => 0, :amount => 0.00)

    customer.add_account_credit(dollars, nil, months)
    add_to_customer_cart_regular(product)
    cart.reload
    assert_equal(expected_use_credit, @controller.can_use_acct_credit(cart, customer))
    assert_equal(expected_use_months, @controller.can_use_univ_month_credits(cart, customer))
  end

  # there are two types of account credit:
  #   * dollars
  #   * months of univ
  # dollars can be used if a cart has a value over $0.01
  #
  # months can be used if the item is a univ
  #
  def test_can_no_acct_credit_for
    #                                                  $     M    $     M
    can_use_credit_test(products(:product_univstub_1), 0.0,  0, false, false)
    can_use_credit_test(products(:product_univstub_1), 5.0,  0, false,  false)
    can_use_credit_test(products(:product_univstub_1), 0.0,  5, false, true)
    can_use_credit_test(products(:product_univstub_1), 5.0,  5, false,  true)
    
    can_use_credit_test(products(:product1), 0, 0, false, false)
    can_use_credit_test(products(:product1), 10, 0, true, false)
    can_use_credit_test(products(:product1), 0, 10, false, false)
    can_use_credit_test(products(:product1), 10, 10, true, false)

  end

end

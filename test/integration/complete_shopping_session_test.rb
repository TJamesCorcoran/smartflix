require "#{File.dirname(__FILE__)}/../test_helper"

class CompleteShoppingSession < ActionController::IntegrationTest
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup
    $FAULT = nil
    Cart.destroy_all
    CartItem.destroy_all
    CreditCard.destroy_all
    LineItem.destroy_all
    Order.destroy_all
    Payment.destroy_all

    unless AbTest.find_by_name("UnivFirstMonthDeal")
      AbTester.create_test(:univ_first_month_deal, 6, 0.0, [:none, :fifty_percent, :free])
    end
  end

  #------------------------------
  # tests
  #------------------------------

  def test_first_time_checkout              

    util_add_item_to_cart(products(:product1))    


    util_checkout_from_cart(true, "customer/login.rhtml")
    util_create_new_customer(:pwd => "12345",
                             :email => "complete_process@smartflix.com",
                             :name_first =>"First",
                             :name_last =>"Last",
                             :addr_1 =>"7 Central St",
                             :addr_2 =>"Suite 140",
                             :city => "Arlington",
                             :state_id => 1,
                             :zip => "02474")
    util_place_order(:cc_num =>"370000000000002",
                     :cc_month => Date.today.month,
                     :cc_year => Date.today.year,
                     :expect_success => true)
  end

  def test_checkout_univ_with_cc
    customer = customers(:bob)

    product = products(:product_univstub_1)

    util_login(customer.email, "password")

    util_add_item_to_cart(product)

    util_checkout_from_cart()

    util_place_order(:cc_num =>"370000000000002",
                     :cc_month => Date.today.month,
                     :cc_year => Date.today.year,
                     :expect_success => true)
    payment = Order.find(:all, :limit => 1, :order=> "order_id desc").first.payments.first
    total_revenue = payment.amount.to_f
    new_revenue = payment.amount_as_new_revenue.to_f

    # We had a bug where univ orders would leave cruft in the system -
    # a hanging side effect of a 0-line-item, 0-customer-id order.
    #
    # It was fixed on 21 Oct 2010.
    #
    # This test checks for that bug.
    assert_equal(0, Order.find_all_by_customer_id(0).size)

    # first month is free
    assert_in_delta(total_revenue, 0.01, 0.01)
    assert_in_delta(new_revenue,   0.01, 0.01)
  end

  def test_checkout_univ_with_store_credit                
    customer = customers(:bob)
    credit_amount = 15.00
    customer.add_account_credit(credit_amount)
    product = products(:product_univstub_1)

    util_login(customer.email, "password")

    util_add_item_to_cart(product)

    util_checkout_from_cart()

    util_place_order(:cc_num =>"370000000000002",
                     :cc_month => Date.today.month,
                     :cc_year => Date.today.year,
                     :expect_success => true)
    payment = Order.find(:all, :limit => 1, :order=> "order_id desc").first.payments.first
    total_revenue = payment.amount.to_f
    new_revenue = payment.amount_as_new_revenue.to_f

# XYZFIX P1    assert_in_delta(total_revenue, product.university.subscription_charge.to_f, 0.01)
# XYZFIX P1   assert_in_delta(new_revenue, product.university.subscription_charge - credit_amount, 0.01)
  end

  def test_checkout_univ_with_error  
    customer = customers(:bob)


    util_login(customer.email, "password")

    product = products(:product_univstub_1)
    util_add_item_to_cart(product)

    util_checkout_from_cart()

    $FAULT = "error in univ cc charge"
    util_place_order(:cc_num =>"370000000000002",
                     :cc_month => Date.today.month,
                     :cc_year => Date.today.year,
                     :expect_success => false)

  end


  #------------------------------
  # advanced tests - both shopping then followup billing
  #------------------------------

  def test_checkout_discount_univ_then_bill_monthly     

    verbose = false
    
    testcases = [
                 { :name => "with live CC", :stored => true,  :url => "/woodworking", :cost => 0.01 },
                 { :name => "with stored CC", :stored => false, :url => "/woodworking", :cost => 0.01 },
                ]
    
    testcases.each do |testcase|

      puts "========== #{testcase[:name] }"  if verbose
  
      setup
      reset!
      Date.force_today()

      customer = customers(:bob)
      customer.credit_cards = []
      customer.credit_cards << CreditCard.test_card_good
      customer.save!
      
      product = products(:product_univstub_1)
      
      first_response = get(testcase[:url], {}, {} )
      
      util_login(customer.email, "password")
      
      util_add_item_to_cart(product)

      if testcase[:stored]
        util_add_cc
        util_place_order(:use_stored_cc => true)
      else
        util_place_order(:cc_num =>"370000000000002",
                         :cc_month => Date.today.month,
                         :cc_year => Date.today.year,
                         :expect_success => true)
      end

      customer.reload

      univ_order = customer.orders.last
      payment = univ_order.payments.first

      total_revenue = payment.amount.to_f
      new_revenue = payment.amount_as_new_revenue.to_f
      
      expected_count = 1

      if testcase[:stored]
        assert_equal(1, univ_order.payments.size)
        assert_equal(false, payment.complete, payment.inspect)
        assert_equal(false, payment.successful, payment.inspect)
        assert_equal(testcase[:cost], payment.amount.to_f)

        util_do_univ_charge
        expected_count += 1

        payment = univ_order.payments.first

        assert_equal(expected_count, univ_order.payments.size)
        assert_equal(true, payment.complete, payment.inspect)
        assert_equal(true, payment.successful, payment.inspect)
        assert_equal(testcase[:cost], payment.amount.to_f)

      else

        assert_equal(1, univ_order.payments.size)
        assert_equal(true, payment.complete)
        assert_equal(true, payment.successful)
        assert_equal(testcase[:cost], payment.amount.to_f)
      end

      #----------
      # 1 day forward - expect no billing
      
      Date.force_today(Date.today + 1)
      util_do_univ_charge
      
      univ_order.reload
      assert_equal(expected_count, univ_order.payments.size)
      
      
      #----------
      # 35 days forward - expect billing
      
      Date.force_today(Date.today + 35)
      util_do_univ_charge
      expected_count += 1      

      univ_order.reload
      assert_equal(expected_count, univ_order.payments.size)
      payment = univ_order.payments.first
      assert_equal(true, payment.complete)
      assert_equal(true, payment.successful)
      assert_equal(22.95, payment.amount.to_f)
      
    end
  end

end

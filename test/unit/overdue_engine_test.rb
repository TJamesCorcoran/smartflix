require 'test_helper'
require 'collections/sequenced_hash'

# we don't want our tests to spew the same logging info that our production runs do
#
def null_logger(input) end

Product
Payment
    
class Product
  def replacement_price
    8
  end
end


class OverdueEngineTest < ActiveSupport::TestCase
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup
    Date.force_today()
    ChargeEngine.testing_return_value = nil
    OverdueEngine.logger = method(:null_logger)
  end

  def int_test_charge_weekly(good_cardP, desired_children)
    li = line_items(:charge_yes_first)
    assert(li.children_lis.empty?, "precond: LI should have no children charges")
    
    # it's hard to store a fake good credit card in a fixture, so hack
    # it into place right here
    fake_cc = (good_cardP ? 
               CreditCard.test_card_good :
               CreditCard.test_card_bad )
    
    
    ChargeEngine.testing_return_value =  (good_cardP ? 
                                          [ true, "fake-true-card"] :
                                          [ false, "fake-bad-card"])

    # do the first charge
    #
    OverdueEngine.charge_weekly
    li.reload
    assert(li.children_lis.size == desired_children, "in good_cardP = #{good_cardP} test, LI should have #{desired_children} children ; has #{li.children_lis.size}")    
    if desired_children > 0
      assert(li.children_lis.first.price == Product::LATE_WEEKLY_BASE, "price should be  #{li.children_lis.first.price}")
      assert(li.children_lis.first.parent_line_item_id == li.line_item_id, "parent -> child -> parent")
    end

    # try to charge again - should not create any new orders, in either case
    #
    old_children_lis = li.children_lis.size
    OverdueEngine.charge_weekly
    li.reload
    assert(li.children_lis.size == old_children_lis)
  end
  

  
  def test_charge_weekly_bad()     int_test_charge_weekly(false, 0) end                
  def test_charge_weekly_good()    int_test_charge_weekly(true,  1) end                

  def DO_NOT_RUN_charge_expired_ccs_as_lost()  

    LineItem.find(:all).each { |li|
      li.destroy if li != line_items(:charge_expired_cc)
    }
    
    # We start out w a credit card that expired 2 months ago.
    # We'll pretend that it was reissued with a new expiration of this month.
    cc_number = "4222222222222"
    cc_expir_date = (Date.today << 2).end_of_month
    cc = CreditCard.new(:month => cc_expir_date.month,
                        :year =>  cc_expir_date.year,
                        :number =>  cc_number,
                        :last_name => "hacked #{cc_number}")

    # good = 5424000000000015
    # bad  = 4222222222222
    # on bad cards, dollar figures are used to pick out response code.
    # e.g. $8.00 --> response code 8 "expired"
    # http://www.authorize.net/support/Merchant/Transaction_Response/Response_Reason_Codes_and_Response_Reason_Text.htm
    
    cust = customers(:charge_expired_cc)
    cust.credit_cards << cc

    cust.credit_cards.first.decrypt_using_found_keys
    
    # attempt weekly late charge - no previous failure, so it should do nothing
    OverdueEngine.charge_expired_ccs_as_lost
    cust.credit_cards.first.reload
    assert_equal(0, cust.credit_cards.first.payments.size)
    
    # Note an expiration failure (from, say, weekly charges) try it again.
    # Should fail.
    cc.payments << Payment.create!( :amount => 9.99,
                                    :amount_as_new_revenue => 9.99,
                                    :complete => 1,
                                    :successful => 0,
                                    :updated_at => Time.now(),
                                    :payment_method => "CreditCard",
                                    :customer_id => 1,
                                    :message =>  "The credit card has expired")


    sleep(1)
    OverdueEngine.charge_expired_ccs_as_lost
    cust.credit_cards.first.reload

    # We manufacturered one fake payment above.  Now with one real one, expect 2 total.
    # The new one should also be an expiration.  
    assert_equal(2, cust.credit_cards.first.payments.size)
    assert(cust.credit_cards.first.payments.last.expired_message?)
    assert(cust.credit_cards.first.payments.last.cc_expiration)

    golden_expir_date = (cc_expir_date >> 2).end_of_month
    assert_equal(golden_expir_date , cust.credit_cards.first.payments.last.cc_expiration.to_date)


    # Try it again.
    # Should fail again.
    sleep(1)
    OverdueEngine.charge_expired_ccs_as_lost
    cust.credit_cards.first.reload
    
    assert_equal(3, cust.credit_cards.first.payments.size)
    assert(cust.credit_cards.first.payments.last.expired?)
    assert(cust.credit_cards.first.payments.last.cc_expiration)
    assert_equal( (cc_expir_date >> 3).end_of_month , cust.credit_cards.first.payments.last.cc_expiration.to_date)

    # Let's make it work.
    # Overwrite the CC with a working code
    # Try it again.
    sleep(1)
    num_existing_orders = cust.orders.size

    cust.credit_cards.first.update_attributes(:last_name => "hacked 5424000000000015")
    OverdueEngine.charge_expired_ccs_as_lost
    cust.reload
    
    # No increase in bad charge statuses
    assert_equal(4, cust.credit_cards.first.payments.size)

    # 1 new order - a replacement order, with price $8 (unforunately, we have to use
    # this price to get the above intention-error code stuff working)
    assert_equal(num_existing_orders + 1 , cust.orders.size)
    assert_equal("replacement charge", cust.orders.last.server_name)
    assert_equal(1,    cust.orders.last.payments.size)
    assert_equal(true, cust.orders.last.payments.first.good?)
    assert_equal(8.00, cust.orders.last.total_price)

    # marked the copy as dead, paid by customer
    assert_equal(0, line_items(:charge_expired_cc).copy.status)
    assert_equal(DeathLog::DEATH_LOST_BY_CUST_PAID, line_items(:charge_expired_cc).copy.most_recent_death.newDeathType)
  end


  def util_build_fake_pending_order()

    CreditCard.destroy_all
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all

    
    
    input = { :cust1 => {
        :foo_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :payments => [ { :date=> Date.today - 2, 
                           :amount => 19.98,
                           :status => Payment::PAYMENT_STATUS_DEFERRED,
                           :complete => false, 
                           :successful => false } ],
          :lis => [ {:name => "foo1", :inStock => true},
                    {:name => "foo2", :inStock => true}  ]
        }
      }
    }
    
    build_fake(input)
  end




  def test_charge_pending_no_cc   

    util_build_fake_pending_order

    OverdueEngine.pending_charge
    cust1 = txt2cust(:cust1)
    order = cust1.orders.first
    assert_equal(1,     order.payments.size)
    assert_equal(false, order.payments.last.complete)
    assert_equal(false, order.payments.last.successful)

  end

  def test_charge_pending_good_cc                  

    util_build_fake_pending_order

    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good

    OverdueEngine.pending_charge

    order = cust1.orders.first
    assert_equal(2,     order.payments.size)

    real_payment = order.payments.first

    assert_equal(true,  real_payment.complete)
    assert_equal(true,  real_payment.successful)
  end

  def test_charge_pending_bad_cc          
    Order.destroy_all
    LineItem.destroy_all
    Payment.destroy_all

    verbose = false

    # build a pending order

    util_build_fake_pending_order
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_bad

    # try to charge it for the first time
    #   - keep the pending payment
    #   - add a FAIL payment
    puts "-------------------- 1: initial charge w bad CC (fail)" if verbose
    OverdueEngine.pending_charge
    cust1.reload

    order = cust1.orders.first

    assert_equal(2,     order.payments.size)
    assert_equal(false,  order.payments.last.complete)
    assert_equal(false, order.payments.last.successful)

    # try again - should not attempt another charge, should stay uncompleted
    puts "\n\n\n-------------------- 2: second attempt; do not go (still bad CC)" if verbose

    sleep(1)
    OverdueEngine.pending_charge
    cust1.reload
    order = cust1.orders.first

    assert_equal(2,     order.payments.size)
    assert_equal(false, order.payments.last.complete)
    assert_equal(false, order.payments.last.successful)

    # try again - we add a good card, so it should use good card, achieve success
    puts "\n\n\n-------------------- 3: add good card, try again " if verbose

    sleep(3)
    good_cc = CreditCard.test_card_good
    good_cc.save!
    cust1.credit_cards << good_cc
    cust1.reload


    OverdueEngine.logger = method(:puts)    if verbose
    OverdueEngine.pending_charge

    cust1.reload

    order = cust1.orders.first

    assert_equal(3,     order.payments.size)
    good_payment = order.payments.first


    assert_equal(true,     good_payment.complete)
    assert_equal(true,     good_payment.successful)
    assert_equal(good_cc,  good_payment.credit_card)

    puts "-------------------- 4: do nothing, try again - expect no additional charge" if verbose

    # try again - should not do anything, bc the charge already went through

    sleep(1)
    OverdueEngine.pending_charge
    order = cust1.orders.first


    assert_equal(3,     order.payments.size)
    good_payment = order.payments.first

    assert_equal(true,     good_payment.complete)
    assert_equal(true,     good_payment.successful)
    assert_equal(good_cc,  good_payment.credit_card)


  end

  # customer lost a DVD.  
  #   if he has a good CC, charge him
  #   if he not, don't expect an order
  #
  def helper_lost_dvd_onecust(good)
    # setup
    Customer.destroy_all
    Order.destroy_all
    LineItem.destroy_all
    CreditCard.destroy_all

    # customer with good credit card - should create order
    #

    input = { :cust => {
        :order_1 => { :orderDate => Date.today - 7,
          :server_name => "smartflix.com",
          :lis => [ {:name => "wood1", :dateOut => (Date.today - 7)},
                    {:name => "wood2", :dateOut => (Date.today - 7)}  ]
        }
      }
    }

    build_fake(input)

    cust = txt2cust(:cust)
    orig_order = cust.orders.first

    if good
      cc_good = CreditCard.create!(:customer => cust,
                                   :brand => "master",
                                   :month => Date.today.month,
                                   :year =>  (Date.today.year + 1),
                                   :encrypted_number => "XXX",
                                   :number => "5424000000000015",
                                   :first_name => "fred",
                                   :last_name => "hacked 5424000000000015")
    else
      cc_bad = CreditCard.create!(:customer => cust,
                                  :brand => "master",
                                  :month => Date.today.month,
                                  :year =>  (Date.today.year + 1),
                                  :encrypted_number => "XXX",
                                  :number => "4222222222222",
                                  :first_name => "fred",
                                  :last_name => "hacked 4222222222222")
    end
    cust.reload
    lis = orig_order.line_items

    OverdueEngine.lost_dvd_onecust(cust, lis, {} ) 
    new_order = (Order.find(:all) - [ orig_order ]).first

    if good
      assert(new_order)
      assert_equal(2, new_order.line_items.size)
      
      assert_in_delta(lis.map(&:product).sum(&:replacement_price).to_f, 
                      new_order.line_items.inject(0) { |sum,li| sum + li.price}.to_f,
                      0.001)
    else
      assert(new_order.nil?, new_order.inspect)
    end

  end

  def test_lost_dvd_onecust                
    helper_lost_dvd_onecust(true)
#RAILS3    helper_lost_dvd_onecust(false)
  end

  def bill_univ_students_setup

    # reset the date
    Date.force_today

    # empty any emails
    @emails = ActionMailer::Base.deliveries
    @emails.clear
    ScheduledEmail.destroy_all

    Customer.destroy_all
    University.destroy_all
    Order.destroy_all
    LineItem.destroy_all
    Payment.destroy_all
    AffiliateTransaction.destroy_all
  end

  def test_bill_univ_students              
    # XYZFIX P1 - write this test!
  end 

  def test_dont_bill_univ_students_for_backend_replacements 
    
  end 


  def test_bill_univ_students_expired_ccs

    verbose = false

    expire_date = (Date.today >> 2 ).end_of_month
    valid_date   = expire_date - 70

    warning_date = expire_date - 50
    warning_date = warning_date.first_wday_after(1)

    charge_date  = expire_date - 10
    dead_date    = expire_date >> 2

    [ 
     { :name => "valid card",   :today => valid_date, :w_mail => false, :charge => false },
     { :name => "warning",      :today => warning_date, :w_mail => true,  :charge => false },
     { :name => "charge",       :today => charge_date,   :w_mail => false, :charge => true },
     { :name => "expired card", :today => dead_date, :w_mail => false, :charge => false },
      
    ].each do |test_case|

      test_case[:c_mail] = test_case[:charge]

      puts "========== #{test_case[:name]} ; today == #{Date.today} ; expire == #{expire_date}" if verbose 
 
      bill_univ_students_setup

      Date.force_today(test_case[:today])

      univ = University.create(:name => "wood", :category_id => 1)

      input =  { :cust1 => { :in_field => {"wood" => 2},

          :wood_order => { :orderDate => Date.today - 100,
            :server_name => "wood",
            :univ_dvd_rate => 3,
            :paid => true,
            :lis => [ {:name => "foo1", :inStock => true},
                      {:name => "foo2", :inStock => true},
                      {:name => "foo3", :inStock => true},
                      {:name => "foo4", :inStock => true},
                      {:name => "foo5", :inStock => true},
                      {:name => "foo6", :inStock => true},
                      {:name => "foo7", :inStock => true},
                      {:name => "foo8", :inStock => true},
                      {:name => "foo9", :inStock => true},
                      {:name => "foo10", :inStock => true}
                    ]
          }
        } # cust1
      } # all custs

      build_fake(input)


      cust  = txt2cust("cust1")
      cc = CreditCard.create!(:customer => cust,
                              :brand => "master",
                              :month => expire_date.month,
                              :year =>  expire_date.year,
                              :encrypted_number => "XXX",
                              :number => "5424000000000015",
                              :first_name => "fred",
                              :last_name => "hacked 5424000000000015")
      cust.reload

      real_order = cust.orders.first
      real_prod_ids_in_field = real_order.line_items_in_field.map(&:product_id).to_set

      sleep(1) # we don't want both orders to have the exact same timestamp

      OverdueEngine.bill_univ_students
      
      if test_case[:w_mail] || test_case[:c_mail]

        assert_equal 1, @emails.size, @emails.map(&:body).inspect
        if test_case[:w_mail]
          assert_equal("SmartFlix: Credit Card Expiration Warning - Don't get charged!", @emails[0].subject )
          assert(@emails[0].body.match(/is going to expire soon./))
          assert_equal(2, ScheduledEmail.count)
          ScheduledEmail.find(:all).each do |se| 
            assert_equal(cust.customer_id, se.customer_id )
            assert_equal(:univ_expire_cc_warn, se.email_type.to_sym)
          end
          assert_equal(real_prod_ids_in_field, ScheduledEmail.find(:all).map(&:product_id).to_set)
        elsif test_case[:c_mail]
          assert_equal("SmartFlix: charge for lost videos", @emails[0].subject )
          assert(@emails[0].body.match(/We're writing today about one or more lost DVDs.  We've purchased replacement/))
          assert_equal(2, ScheduledEmail.count)
          ScheduledEmail.find(:all).each do |se| 
            assert_equal(cust.customer_id, se.customer_id )
            assert_equal(:univ_expire_cc_charge, se.email_type.to_sym)
          end
          assert_equal(real_prod_ids_in_field, ScheduledEmail.find(:all).map(&:product_id).to_set)
        else
          raise "error in test"
        end
      else
        assert_equal 0, @emails.size, @emails.map(&:subject).inspect
      end

      cust.reload

      if test_case[:charge]
        assert_equal(2, cust.orders.size)
        replacement = cust.orders.max_by(&:created_at)
        assert_equal(replacement.server_name, "replacement charge")
        assert_in_delta(replacement.payments.first.amount.to_f, 16.0, 0.0001, replacement.payments.first.inspect)
      else
        assert_equal(1, cust.orders.size)
      end



    end # testcase

  end # def

end

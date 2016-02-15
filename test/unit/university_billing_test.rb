require 'test_helper'
require 'collections/sequenced_hash'

# we don't want our tests to spew the same logging info that our production runs do
#
def null_logger(input) 
  # control VERBOSE-ness here:
  # puts input 
end

class UniversityBillingTest < ActiveSupport::TestCase
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  
  def setup
    OverdueEngine.logger = method(:null_logger)
  end
  
  def util_build_fake_univ_order(options)
    options.allowed_and_required([:paid], [])
    
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all
    
    wood_univ  = University.create(:name => "wood", :category_id => 1)
    
    input = { :cust1 => {
        :wood_order => { :orderDate => Date.today - 7,
          :univ_dvd_rate => 3,
          :server_name => "wood",
          :paid => options[:paid],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true}  ]
        }
      }
    }
    
    build_fake(input)
  end
  
  def util_payments_by_goodness(customers)
    ret = {}
    customers.each do |cust|
      cust.reload
      ret[cust] = {}
      ret[cust][:good] = cust.orders.first.payments.select { |p| p.good?}
      ret[cust][:bad] = cust.orders.first.payments.select { |p| ! p.good?}
    end
    ret
  end
  
  
  
  #--------------------------------------------------
  #--------------------------------------------------
  #--------------------------------------------------
  #--------------------------------------------------
  #--------------------------------------------------
  
  def test_bill_univ_student_good_cc          
    util_build_fake_univ_order(:paid => false)
    
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good
    
    # PRE-COND: 
    #   cust1: 1 payment - which bad
    
    ret = util_payments_by_goodness( [ cust1 ])
    assert_equal(1, ret[cust1][:bad].size)
    assert_equal(0, ret[cust1][:good].size)
    
    # try to bill
    #    cust1: 2 payments - 1 bad  (original) 1 good,
    #
    
    util_do_univ_charge
    
    ret = util_payments_by_goodness( [ cust1 ])
    assert_equal(1, ret[cust1][:bad].size)
    assert_equal(1, ret[cust1][:good].size)
    
    # try to bill a second time
    #    cust1: no more payments
    util_do_univ_charge
    
    ret = util_payments_by_goodness( [ cust1 ])
    assert_equal(1, ret[cust1][:bad].size)
    assert_equal(1, ret[cust1][:good].size)
    
    # advance date 5 weeks - another charge should work
    begin
      Date.force_today(Date.today + 35)
      util_do_univ_charge
      
      ret = util_payments_by_goodness( [ cust1 ])
      assert_equal(1, ret[cust1][:bad].size)
      assert_equal(2, ret[cust1][:good].size)
      
      ret = util_payments_by_goodness( [ cust1 ])
      assert_equal(1, ret[cust1][:bad].size)
      assert_equal(2, ret[cust1][:good].size)
      
      Date.force_today(Date.today + 35)
      util_do_univ_charge
      
      ret = util_payments_by_goodness( [ cust1 ])
      assert_equal(1, ret[cust1][:bad].size)
      assert_equal(3, ret[cust1][:good].size)
      
      ret = util_payments_by_goodness( [ cust1 ])
      assert_equal(1, ret[cust1][:bad].size)
      assert_equal(3, ret[cust1][:good].size)
      
    ensure
      # reset date
      Date.force_today
    end
    
  end
  
  def test_bill_univ_student_bad_cc          
    
    util_build_fake_univ_order(:paid => false)
    
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_bad
    
    
    # PRE-COND: 
    #   cust1: 1 payment - bad
    
    ret = util_payments_by_goodness( [  cust1 ])
    assert_equal(1, ret[cust1][:bad].size)
    assert_equal(0, ret[cust1][:good].size)
    
    # try to bill
    #    cust1: 1 new bad payment
    #
    
    util_do_univ_charge
    
    ret = util_payments_by_goodness( [ cust1 ])
    assert_equal(2, ret[cust1][:bad].size)
    assert_equal(0, ret[cust1][:good].size)
    
    # try to bill
    #    cust1: CC has been marked as invalid - no charges attempted
    #
    
    5.times do 
      util_do_univ_charge
      
      ret = util_payments_by_goodness( [ cust1 ])
      assert_equal(2, ret[cust1][:bad].size)
      assert_equal(0, ret[cust1][:good].size)
    end
    
    # add a new CC - it looks good, so we attempt to charge it... but it's bad
    #
    
    cust1.credit_cards.each { |cc| cc.destroy }
    cust1.credit_cards << CreditCard.test_card_bad
    
    util_do_univ_charge
    
    ret = util_payments_by_goodness( [ cust1 ])
    assert_equal(3, ret[cust1][:bad].size)
    assert_equal(0, ret[cust1][:good].size)
    
    
    # add a new CC - it looks good, so we attempt to charge it... and it works!
    #
    
    cust1.credit_cards.each { |cc| cc.destroy }
    cust1.credit_cards << CreditCard.test_card_good
    
    util_do_univ_charge
    
    ret = util_payments_by_goodness( [ cust1 ])
    assert_equal(3, ret[cust1][:bad].size)
    assert_equal(1, ret[cust1][:good].size)
    
  end
  
  def test_bill_univ_student_account_credit          
    util_build_fake_univ_order(:paid => false)
    
    cust1 = txt2cust(:cust1)
    cust1.add_account_credit(nil, nil, 1)
    
    # PRE
    assert_equal(false, cust1.orders.first.univ_fees_current?)
    assert_equal(1,     cust1.credit_months)
    
    # try to bill
    #    cust1: 1 new bad payment
    #
    
    util_do_univ_charge
    
    cust1.reload
    cust1.orders.first.reload
    
    # POST
    assert_equal(true, cust1.orders.first.univ_fees_current?)
    assert_equal(0,    cust1.credit_months)    
    
  end
  
  # this student has no items pending or in the field - should not be charged
  #
  def test_bill_univ_student_not_active        
    
    # setup
    util_build_fake_univ_order(:paid => false)
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good
    order = cust1.orders.first
    order.cancel
    
    before_payments_size = order.payments.size
    
    
    # test 1 - test the attributes that we use 
    assert_equal(false, order.line_items_pending_any?)
    assert_equal(false, order.any_in_field?)
    
    util_do_univ_charge
    
    # test 2 - ensure that we did not charge
    order.reload
    assert_equal(before_payments_size,    order.payments.size)    
  end
  
  # this student has pending items - CHARGE HIM!
  #
  def test_bill_univ_student_active_unshipped      
    
    # setup
    util_build_fake_univ_order(:paid => false)
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good
    
    order = cust1.orders.first
    
    before_payments_size = order.payments.size
    
    # test 1 - test the attributes that we use 
    assert_equal(true, order.line_items_pending_any?)
    assert_equal(false, order.any_in_field?)
    
    util_do_univ_charge
    
    # test 2 - ensure that we charged
    order.reload
    assert_equal(before_payments_size + 1,    order.payments.size)    
  end
  
  # this student has items in the field - CHARGE HIM!
  #
  def test_bill_univ_student_active_infield      
    
    # setup
    util_build_fake_univ_order(:paid => false)
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good
    
    order = cust1.orders.first
    sh = Shipment.create!(:dateOut => Date.today, :time_out => Time.now)
    order.line_items.each { |li| li.update_attributes(:shipment => sh) }
    
    before_payments_size = order.payments.size
    
    
    
    # test 1 - test the attributes that we use 
    assert_equal(false, order.line_items_pending_any?)
    assert_equal(true, order.any_in_field?)
    
    util_do_univ_charge
    
    # test 2 - ensure that we charged
    order.reload
    assert_equal(before_payments_size + 1,    order.payments.size)    
  end
  
  def test_bill_univ_student_active_infield_and_pending      
    
    # setup
    util_build_fake_univ_order(:paid => false)
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good
    
    order = cust1.orders.first
    sh = Shipment.create!(:dateOut => Date.today, :time_out => Time.now)
    order.line_items[0,2].each { |li| li.update_attributes(:shipment => sh) }
    
    before_payments_size = order.payments.size
    
    
    # test 1 - test the attributes that we use 
    assert_equal(true, order.line_items_pending_any?)
    assert_equal(true, order.any_in_field?)
    
    util_do_univ_charge
    
    # test 2 - ensure that we charged
    order.reload
    assert_equal(before_payments_size + 1,    order.payments.size)    
  end
  

  # In mid-nov 2011 we boost prices by $1.99
  #
  def test_bill_univ_price_increase_internal    
    Date.force_today("2011-11-20")
    util_build_fake_univ_order(:paid => false)
    cust1 = txt2cust(:cust1)
    cust1.credit_cards << CreditCard.test_card_good
    util_do_univ_charge
    assert_in_delta(cust1.orders.first.payments.first.amount.to_f, 24.94, 0.001)
    
  ensure
    # reset date
    Date.force_today
  end

  
  #--------------------------------------------------
  #--------------------------------------------------
  #--- cross between univ and late fees
  #--------------------------------------------------
  #--------------------------------------------------
  

  # bug 11: 
  # http://trac.smartflix.com/ticket/11
  # Jen insists that manual "don't count" items in univs are generating late fees

  def test_no_late_fees_on_univ_replacement_items
    Customer.destroy_all
    LineItem.destroy_all
    Order.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all
    
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { :cust1 => { :in_field => {"wood" => 4} }   }
    build_fake(input)
    LineItem.first.update_attributes(:ignore_for_univ_limits => true)

    if false
      puts "== li"
      LineItem.find(:all).each { |li| puts " * #{li.inspect}" }
      puts "== Order"
      Order.find(:all).each  { |oo| puts " * #{oo.inspect}" }
    end
    cust  = txt2cust("cust1")
  
    Date.force_today(Date.today + 90)
  
    chargeable = LineItem.late_items_chargeable

    assert(chargeable.empty?)
  end

end


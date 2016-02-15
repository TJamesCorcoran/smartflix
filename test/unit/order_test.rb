require 'test_helper'

class OrderTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup

  end

  def test_note_lost_charge    
    # create a "real" order
    real_order = Order.create(:customer_id =>1, :orderDate => Date.today, :server_name => "smartflix.com")
    real_li = LineItem.create(:product_id => 1, :order => real_order)

    # ... and check it
    # real_order = Order.find(:all)[0]
    # assert_equal(real_order.id, starting_id)

    # prep the stuff we need for a call
    customer = customers(:overdue_cust)
    li = line_items(:overdue_copy)
    
    overdue_order = Order.note_lost_charge( customer, [li] )

    assert_equal(1, overdue_order.line_items.size)
    
  end

  def test_chargeable    
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all

    input = {
      :cust1 => {
        :wood_order => { :orderDate => Date.today,
          :paid => false,
          :lis => [ {:name => "wood1", :inStock => true, :cancelled => false},
                    {:name => "wood2", :inStock => true, :cancelled => false}
                  ]
        }
      },
      :cust2 => {
        :wood_order => { :orderDate => Date.today,
          :paid => false,
          :lis => [ {:name => "wood1", :inStock => true, :cancelled => true},
                    {:name => "wood2", :inStock => true, :cancelled => false}
                  ]
        }
      },    
      :cust3 => {
        :wood_order => { :orderDate => Date.today,
          :paid => false,
          :lis => [ {:name => "wood1", :inStock => true, :cancelled => true},
                    {:name => "wood2", :inStock => true, :cancelled => true}
                  ]
        }
      },
      :cust4 => {
        :wood_order => { :orderDate => Date.today,
          :paid => false,
          :lis => [ {:name => "wood1", :inStock => true, :cancelled => true},
                    {:name => "wood2", :inStock => true, :cancelled => true}
                  ]
        }
      },
    }
    
    build_fake(input)
   
    order_1 = txt2cust("cust1").orders.first
    assert_equal(true, order_1.chargeable?)

    order_2 = txt2cust("cust2").orders.first
    assert_equal(true, order_2.chargeable?)

    order_3 = txt2cust("cust3").orders.first
    assert_equal(false, order_3.chargeable?)

 
  end

  def teardown
    Date.force_today(nil)
  end


  
  def test_entirely_unshipped      
    tests = [  { :num_shipped_items =>1, :num_unshipped_items =>0, :expected => false },
               { :num_shipped_items =>5, :num_unshipped_items =>5, :expected => false },
               { :num_shipped_items =>0, :num_unshipped_items =>1, :expected => true },
               { :num_shipped_items =>0, :num_unshipped_items =>5, :expected => true } ]
    tests.each do |test_h|
      ii = 0
      order = Order.new 
      test_h[:num_shipped_items].times   { order.line_items << LineItem.new(:live =>true, :shipment => Shipment.new ) }
      test_h[:num_unshipped_items].times { order.line_items << LineItem.new(:live =>true) }

      ret = order.entirely_unshipped?
      assert_equal(test_h[:expected], ret, "#{test_h[:num_unshipped_items]} unshipped, #{test_h[:num_shipped_items]} shipped, expect #{test_h[:expected]}, got #{ret}")
    end
  end

  # the "university month" for a given customer is the month-long
  # period starting at their last successful payment
  #
  def test_univ_month      
    
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all
    
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { 

      # normal case
      :cust1 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 5,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 5, 
                           :complete => true, 
                           :successful => true,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :inStock => true},
                    {:name => "smart2", :inStock => true},
                    {:name => "smart3", :inStock => true},
                    {:name => "smart4", :inStock => true}]
        },
      },

      # failed charge
      :cust2 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 15,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 15, 
                           :complete => true, 
                           :successful => false,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :inStock => true},
                    {:name => "smart2", :inStock => true},
                    {:name => "smart3", :inStock => true},
                    {:name => "smart4", :inStock => true}]
        },
      },

    }
    build_fake(input)
    cust1 = txt2cust(:cust1)
    cust2 = txt2cust(:cust2)
    cust3 = txt2cust(:cust3)

    assert_equal(Date.today - 5, cust1.orders.first.univ_month_begin )
    assert_equal((Date.today - 6) >> 1 , cust1.orders.first.univ_month_end)

    assert_equal(Date.today - 15, cust2.orders.first.univ_month_begin )
    assert_equal((Date.today - 16) >> 1, cust2.orders.first.univ_month_end )

    
  end
  
  def test_live_university    

    # this is an ugly hack, because I can't get order(:univ_order) to work, even using
    #      set_fixture_class :order => "Order"
    order = line_items(:univ_order_a).order
    order.payments << Payment.create(:amount => 22.95, 
                                     :amount_as_new_revenue => 22.95,
                                     :payment_method => "Credit Card",
                                     :customer_id => order.customer_id,
                                     :complete => true, :successful => true)
    assert_equal(false, order.live_university_at?("2008-01-01"))
                                                                   # order placed on 2 Jan
    assert_equal(true,  order.live_university_at?("2008-01-03"))
                                                                   # item A ships on 5 Jan
    assert_equal(true,  order.live_university_at?("2008-01-05"))
                                                                   # item A returns on 7 Jan
    assert_equal(true,  order.live_university_at?("2008-01-10"))
                                                                   # item B ships on 10 Jan
    assert_equal(true,  order.live_university_at?("2008-01-12"))
                                                                   # item B returns on 14 Jan
    assert_equal(true,  order.live_university_at?("2008-01-15"))
                                                                   # item C cancelled on 20 Jan
    assert_equal(false,  order.live_university_at?("2008-01-21"))
    assert_equal(false,  order.live_university_at?("2008-12-31"))

    # XYZFIX P2 need testing of payments / credit card viability
  end

  def test_univ_fees_current      
    # this is a crappy test bc the dates are coded into the fixtures
    assert_equal true,   orders(:univ_order_current).univ_fees_current?
    assert_equal false,  orders(:univ_order_none_recent).univ_fees_current?
    assert_equal false,  orders(:univ_order_none).univ_fees_current?
    assert_equal false,  orders(:univ_order_recent_but_no_successful).univ_fees_current?
  end

  def test_univ_payed_up      
    Date.force_today("2009-03-30")

    assert_equal(true,    orders(:univ_payed_up_yes).univ_payed_up?)
    assert_equal(false,   orders(:univ_payed_up_outofdate).univ_payed_up?)
    assert_equal(false,   orders(:univ_payed_up_recent_failure).univ_payed_up?)

    Date.force_today(nil)
  end

  def test_univ_fee_amount_to_charge      
    partial = 15.00
    full = universities(:univ_1).subscription_charge_for_n(3)

    assert_equal(full,    orders(:test_univ_fee_amount_to_charge_not_payed_full).univ_fee_amount_to_charge)
    assert_equal(partial, orders(:test_univ_fee_amount_to_charge_not_payed_discount).univ_fee_amount_to_charge)
    assert_equal(full,    orders(:test_univ_fee_amount_to_charge_not_payed_full_failed_to_charge).univ_fee_amount_to_charge)
    assert_equal(partial, orders(:test_univ_fee_amount_to_charge_not_payed_discount_failed_to_charge).univ_fee_amount_to_charge)
    assert_equal(full,    orders(:test_univ_fee_amount_to_charge_payed_full).univ_fee_amount_to_charge)
    assert_equal(full,    orders(:test_univ_fee_amount_to_charge_payed_discount).univ_fee_amount_to_charge)
    throws = false
    begin
      assert_equal(YY, orders(:test_univ_fee_amount_to_charge_not_univ).univ_fee_amount_to_charge)
    rescue
      throws = true
    end
    assert(throws)
  end


  def test_create_backend_replacement_order  
    # When a shipment gets lost we want to replace it.
    # The replacement orders should: 
    #   * have the same titles
    #   * preserve the univ id
    #   * have each LI pt to the parent LI that it replaces 

    [
     { :name => "regular",         :ship => shipments(:toreplace_order_regular) },
     { :name => "univ",            :ship =>shipments(:toreplace_order_univ)}, 
     { :name => "mixed",           :ship =>shipments(:toreplace_order_mixed_ship ) }
    ].each do |hh|
      # puts "=== #{hh[:name]}"
      ship = hh[:ship]

#       puts "AAA-1 #{ship.inspect}"
#       puts "AAA-2 #{ship.line_items.map(&:product_id)}"
#       puts "AAA-3 #{ship.orders.inspect}"
#       puts "AAA-4 #{ship.orders.map{|o| o.university.andand.name}.inspect}"
#       puts "AAA-5 #{ship.orders.first.inspect}"
#       puts "AAA-6 #{ship.orders.first.customer.inspect}"
      

      new_orders = Order.create_backend_replacement_order(ship.customer, ship.line_items)



      new_lis = new_orders.map(&:line_items).flatten
     
      assert_equal(ship.orders.uniq.size, new_orders.size)
      assert_equal(0, new_lis.select { |li| li.parent_line_item_id.nil?}.size )
      assert_equal(ship.line_items.map(&:product_id).to_set, new_lis.map(&:product_id).to_set)
      assert_equal(ship.line_items.map{|li| li.order.university.andand.name}.to_set, new_lis.map{|li| li.order.university.andand.name}.to_set)

      

      # make sure that the order is payed for
      new_orders.each { |order|
        assert_equal(true, order.most_recent_payment_good.to_bool)
      }

      new_orders.select {|o| o.university}.each { |new_order|
        assert_equal(0, new_order.line_items.select {|li| ! li.ignore_for_univ_limits}.size)
      }
    end
  end

  def test_univ_status
    univ = University.create(:name => "wood", :category_id => 1)

    input =  { 
      :cust => {
        :in_field => { "wood" => 3},
        :univ_order => { 
          :univ_dvd_rate => 3,
          :orderDate => Date.today - 7,
          :server_name => "wood",
          :paid => true,
          :lis => [ {:name => "wood1", :inStock => false},
                    {:name => "wood2", :inStock => false},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood7", :inStock => true}  ]
        }
      }
    }
    
    build_fake(input)

    cust = txt2cust(:cust)
    order = cust.orders.first

    #----------
    # cancel all items -> :cancelled_in_field
    order.cancel
    order.reload
    assert_equal(:cancelled_in_field, order.univ_status)

    #----------
    # return all items -> :cancelled_full
    order.line_items.each { |li| li.copy.return_to_stock if li.in_field? }    
    assert_equal(:cancelled_full, order.univ_status)

    #

    Order.destroy_all
    Customer.destroy_all
    LineItem.destroy_all
    Payment.destroy_all

    build_fake(input)

    cust = txt2cust(:cust)
    order = cust.orders.first

    #----------
    # live
    assert_equal(:live, order.univ_status)

    #----------
    # live, unpaid in field
    
    # advance the date a year, but don't create new payments
    Date.force_today(Date.today >> 12)
    assert_equal(:live_unpaid_in_field, order.univ_status)

    #----------
    # live, unpaid
    order.line_items.each { |li| li.copy.return_to_stock if li.in_field? }    
    assert_equal(:live_unpaid, order.univ_status)
  end

end

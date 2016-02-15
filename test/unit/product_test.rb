require 'test_helper'

require 'date'
# to use:
#     1) rake db:test:prepare
#     2) ruby test/unit/copy_test.rb

$customer_to_univ_to_remaining = Hash.new { |hash, key| hash[key] = Hash.new }

class Customer
  attr_accessor :dvds_remaining

  def dvds_remaining_for_univ(univ) 
    
    $customer_to_univ_to_remaining[self][univ].to_i
  end

end


class ProductTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # Test ferret searches
  def test_ferret      

    Product.rebuild_index

    # Basic, three have boats
    products = Product.find_by_contents_for_listing('boats')
    assert_equal(3, products.size)
    assert_equal(products(:product1), products[0])
    assert_equal(products(:product2), products[1])
    # don't expect id == 4  to appear, because it's not first in set
    assert_equal(products(:product5), products[2])

    # Basic, two have trees
    products = Product.find_by_contents_for_listing('trees')
    assert_equal(2, products.size)
    assert_equal(products(:product3), products[0])
    assert_equal(products(:product5), products[1])

    # Tricky, second title in set has avocados, we should get first title
    products = Product.find_by_contents_for_listing('avocados')
    assert_equal(1, products.size)
    assert_equal(products(:product5), products[0])

  end    

  # Test the functionality for getting a list of featured products
  def test_featured          

    featured = Product.featured()
    assert_equal(2, featured.size)
    assert_equal(products(:product2), featured[0])
    assert_equal(products(:product5), featured[1])

    # Make sure :order works, can't really test that the random one is random
    featured = Product.featured(:order => :linear)
    assert_equal(2, featured.size)
    assert_equal(products(:product2), featured[0])
    assert_equal(products(:product5), featured[1])
    featured = Product.featured(:order => :weighted_random)
    assert_equal(2, featured.size)

    # Make sure :limit works
    featured = Product.featured(:limit => 1)
    assert_equal(1, featured.size)
    assert_equal(products(:product2), featured[0])

    # Make sure :category works, for a leaf category and a base category
    featured = Product.featured(:category => Category.find(3))
    assert_equal(1, featured.size)
    assert_equal(products(:product5), featured[0])
    featured = Product.featured(:category => Category.find(1))
    assert_equal(2, featured.size)
    assert_equal(products(:product2), featured[0])
    assert_equal(products(:product5), featured[1])

    # Make sure :skip_products works
    featured = Product.featured(:skip_products => products(:product2))
    assert_equal(1, featured.size)
    assert_equal(products(:product5), featured[0])
    
  end

  # Make sure avg rating calculation is correct
  def test_avg_rating          
    assert_equal(4.5, products(:product1).avg_rating)
    assert_equal(3.5, products(:product2).avg_rating)
  end

  # Make sure selection of ratings vs. reviews is correct
  def test_ratings_reviews          
    assert_equal(2, products(:product1).ratings.size)
    assert_equal(2, products(:product1).reviews.size)
    assert_equal(2, products(:product2).ratings.size)
    assert_equal(1, products(:product2).reviews.size)
  end

  # Make sure recommendations work
  def test_recommendations          
    recs = products(:product1).product_recommendations
    assert_equal(2, recs.size)
    assert_equal(products(:product5), recs[0])
    assert_equal(products(:product3), recs[1])
  end

  # Make sure set membership works
  def test_sets          
    assert(!products(:product1).product_set_member?)
    assert(products(:product4).product_set_member?)
    assert(products(:product5).product_set_member?)
    assert_equal(1, products(:product5).product_set_ordinal)
    assert_equal(2, products(:product4).product_set_ordinal)
    assert_equal(products(:product5), products(:product4).product_set.first)
    assert_equal(products(:product5), products(:product4).product_set.products[0])
    assert_equal(products(:product4), products(:product4).product_set.products[1])
    assert_equal(products(:product5), products(:product5).product_set.products[0])
    assert_equal(products(:product4), products(:product5).product_set.products[1])
  end

  # Make sure the listing name for products is correct for set and non-set
  def test_listing_name          
    assert_equal('Product1', products(:product1).listing_name)
    assert_equal('Product set 1', products(:product5).listing_name)
    assert_equal('Product set 1', products(:product4).listing_name)
  end

  # Make sure the summary works
  def test_summary          
    assert_equal('Description of product 1, about boats', products(:product1).summary)
    assert_equal('Description of product 1, about boats', products(:product1).summary(37))
    assert_equal('Description of product 1, about', products(:product1).summary(31))
    assert_equal('Description of product 1, about', products(:product1).summary(36))
  end

  # Make sure new titles listing works
  def test_new          
    assert_equal(3, Product.find_new_for_listing(:limit => 3).size)
    assert_equal(products(:product5), Product.find_new_for_listing(:limit => 3)[0])
    assert_equal(products(:product3), Product.find_new_for_listing(:limit => 3)[1])
  end

  # Make sure author name works
  def test_author_name          
    assert_equal('Arthur Author', products(:product1).author_name)
    assert_nil(Product.new().author_name)
  end

  def test_backorderedness          
    assert_equal(40, products(:product_backordered1).days_backorder)
    assert_equal(40, products(:product_backordered2).days_backorder)
    assert_equal(0, products(:product1).days_backorder)
    assert_equal(0, Product.new().days_backorder)

    assert(!products(:product_backordered3).backordered?)
    assert(!products(:product_backordered3).backordered?(5))

    assert(products(:product_backordered3).backordered?(0))

    p1 = Product.new
    p1.days_backorder = 10
    assert_equal(10, p1.days_backorder)
    assert(!p1.backordered?)
  end
  
  def test_savings_calculations          
    # for a DVD that stands alone, we should just compare
    # the rental of 1 DVD to the purchase of 1 DVD
    prod = products(:product1)
    assert_equal(69.99, prod.comparison_purchase_price)
    assert_equal( 9.99, prod.comparison_rental_price)
    assert_equal(60.00, prod.comparison_savings)
    assert_equal(85,    prod.comparison_savings_percent)

    # for a DVD that stands alone (and has no price), we should pick 
    # a default value
    prod = products(:product_noprice)
    assert_equal(40.00, prod.comparison_purchase_price)
    assert_equal( 9.99, prod.comparison_rental_price)
    assert_equal(30.01, prod.comparison_savings)
    assert_equal(75,    prod.comparison_savings_percent)
    
    # for a DVD in a set, should compare
    # the rental of the rest to the purchase of the set
    prod = products(:savings_product_1)
    assert_equal(209.97, prod.comparison_purchase_price)
    assert_equal( 23.98, prod.comparison_rental_price)
    assert_equal(185.99, prod.comparison_savings)
    assert_equal(    88,    prod.comparison_savings_percent)

    # for a DVD in a set with no price info, should compare
    # the rental of the rest to the purchase of the set
    prod = products(:savings_product_31)
    assert_equal(149.99, prod.comparison_purchase_price)
    assert_equal( 23.98, prod.comparison_rental_price)
    assert_equal(126.01, prod.comparison_savings)
    assert_equal(    84,    prod.comparison_savings_percent)
  end


  def clean_setup
    Customer.destroy_all
    LineItem.destroy_all
    Order.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all
    PotentialShipment.destroy_all
    PotentialItem.destroy_all
  end

  # setup unfulfilled orders
  def setup_cust_orders(tt, test)
    test[:custords].keys.each do | daysago |
      num_orders = test[:custords][daysago]
      num_orders.times do | ii |
        oo = Order.create!(:server_name =>"smartflix.com", :orderDate => (Date.today - daysago), :customer=> customers(:one_at_a_time))
        li = LineItem.create!(:product => tt, :order=> oo, :live => true)
      end
    end
  end

  # setup univ
  def setup_univ_orders(tt, test)

    uni = University.create(:name => String.random_alphanumeric)

    return if test[:univords].nil?

    test[:univords].keys.each do | remaining_for_univ |
      num_univ_custs = test[:univords][remaining_for_univ]
      num_univ_custs.times do | ii |
        ship = Address.test_shipping_addr
        bill = Address.test_billing_addr
        ship.save!
        bill.save!

        email = "#{String.random_alphanumeric}@smartflix.com"
        cu = Customer.new(:created_at => Time.now,
                          :email => email,
                          :shipping_address => ship,
                          :billing_address => bill,
                          :password => "password")
        cu.save!
        $customer_to_univ_to_remaining[cu][uni] = remaining_for_univ
        
        oo = Order.create!(:orderDate => (Date.today - 200),
                           :server_name => "foobar university",
                           :customer=> cu,
                           :university => uni)
        li = LineItem.create!(:product => tt, :order=> oo, :live => true)
      end
    end
  end

  def setup_dvds(tt, test, status)
    kk =  (status == 1) ? :good : :bad
    test[kk].keys.each do | remaining |
      num_orders = test[ kk ][remaining]
      daysago = 21 - remaining   # XYZFIX P4 replace this magic number with a reference to code inside copy that specifies expected customer turnaround time
      num_orders.times do | ii |
        stock = nil
        ss = nil
        if (0 == remaining)
          stock = 1
        else
          ss = Shipment.new(:dateOut => (Date.today - daysago), :time_out => (Date.today - daysago))
          ss.save
          stock = 0
        end
        cc = Copy.create!(:product =>tt,
                          :birthDATE=>"1900-01-01",
                          :status => status,
                          :inStock => stock)
#        oo = Order.create!(:orderDate => (Date.today - daysago), :customer=> customers(:previous_customer))
#        li = LineItem.create!(:product => tt, :copy => cc, :shipment=> ss, :order =>oo)
      end
    end
  end

  def setup_dvds_bad(tt, test)
     setup_dvds(tt, test, 0)
  end

  def setup_dvds_good(tt, test)
     setup_dvds(tt, test, 1)
  end

  def setup_vendor_orders(tt, test)
    total = 0
    test[:ordered].keys.each do | remaining |
      daysago = 5 - remaining  # XYZFIX P4 replace this magic number with a reference to code inside product that picks expected delay
      num_orders = test[:ordered][remaining]
      total  += num_orders
      vo = VendorOrderLog.new(:product => tt, :orderDate => (Date.today - daysago), :quant =>num_orders)
      vo.save
    end

    io = tt.inventory_ordered
    if io.nil?
      io = InventoryOrdered.create!(:product => tt, :quant_dvd => 0 )
    end
    io.quant_dvd += total
    io.save
  end

  def test_customerLocationInQueue    
    clean_setup

    wood_univ  = University.create(:name => "wood", :category_id => 1)

    input =  {
      :cust1 => {
        :order_1 => { :orderDate => Date.today - 7,
          :paid => true,
          :lis => [ {:name => "prod1" }]
        }
      },

      :cust2 => {
        :order_1 => { :orderDate => Date.today - 14,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "prod1" }]
        }
      },
      
      :cust3 => {
        :order_1 => { :orderDate => Date.today - 21,
          :server_name => "late charge",
          :paid => true,
          :lis => [ {:name => "prod1" } ]
        },
      }
    }
    
    build_fake(input)
    
    cust1  = txt2cust("cust1")
    cust2  = txt2cust("cust2")
    cust3  = txt2cust("cust3")

    prod = txt2tit( "prod1")

    # in the normal case, go strictly by date
    assert_equal(0, prod.customerLocationInQueue(cust3.customer_id))
    assert_equal(1, prod.customerLocationInQueue(cust2.customer_id))
    assert_equal(2, prod.customerLocationInQueue(cust1.customer_id))

    # if we say "ignore univs", then ... ignore univs
    assert_equal(0, prod.customerLocationInQueue(cust3.customer_id, :ignore_univs => true))
    assert_equal(1, prod.customerLocationInQueue(cust2.customer_id, :ignore_univs => true))
    assert_equal(1, prod.customerLocationInQueue(cust1.customer_id, :ignore_univs => true))
    
  end


  def test_tobuys_univstub                
    assert_equal [0,0], products(:tobuy_title_univstub).copies_needed
  end

  # There are no active LIs for the product, therefore there should be no copies needed.
  # This tests a fix of a bug where we used to count late and replacement LIs as real LIs.
  def test_copies_needed_ignore_replacement_and_late_fees                
    title_name = "copies needed test 1"

    input =  {
      :cust1 => {
        :order_1 => { :orderDate => Date.today - 7,
          :paid => true,
          :lis => [ {:name => title_name, :dateOut => (Date.today - 5) } ]
        }
      },


      :cust2 => {
        :order_1 => { :orderDate => Date.today - 21,
          :server_name => "late charge",
          :paid => true,
          :lis => [ {:name => title_name } ]
        },
        :order_2 => { :orderDate => Date.today - 14,
          :server_name => "late charge",
          :paid => true,
          :lis => [ {:name => title_name } ]
        },
        :order_3 => { :orderDate => Date.today - 7,
          :server_name => "late charge",
          :paid => true,
          :lis => [ {:name => title_name } ]
        }
      },
      :cust3 => {
        :order_1 => { :orderDate => Date.today - 21,
          :server_name => "replacement charge",
          :paid => true,
          :lis => [ {:name => title_name } ]
        },

      },
    }

    build_fake(input)

    product = Product.find_by_name(title_name)
    # print "XXX #{product.copies.inspect}"
    # print "\n"
    # print "YYY #{product.copies_needed.inspect}"

    needed, pain = product.copies_needed
    assert_equal(0, needed)
  end

  def test_tobuy_update
    #       custords = X days ago, Y dvds were ordered
    #       univords = X days ago, Y dvds were ordered from universities
    #       good     = how many good DVDs will be here in X days
    #       bad      = how many bad  DVDs will be here in X days
    #       ordered  = how many newly purchased  DVDs will be here in X days
    #       expected = how many DVDs do we expect to be told to purchase
    #
    #   key = "days ago"
    #   value = number
    test_array = [
                  # basic: we've got orders and no copies to fill them with
                  { :name => "basic 1", :custords => { 0 => 0}, :good => { 0 => 0, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 1},
                  { :name => "basic 2", :custords => { 0 => 1}, :good => { 0 => 0, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 1},
                  { :name => "basic 3", :custords => { 0 => 2}, :good => { 0 => 0, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 1},
                  { :name => "basic 4", :custords => { 0 => 10}, :good => { 0 => 0, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 3},

                  # copies are either in stock now, or will be shortly.
                  { :name => "copies 1", :custords => { 40 => 20}, :good => { 0 => 0, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 7},    #20  XYZFIX P2
                  { :name => "copies 2", :custords => { 40 => 20}, :good => { 0 => 20, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 0},
                  { :name => "copies 3", :custords => { 40 => 20}, :good => { 0 => 10, 5 => 0, 21 => 0 }, :bad => {  }, :ordered => { }, :expected => 0},   #10  XYZFIX P2
                  { :name => "copies 4", :custords => { 20 => 20}, :good => { 0 => 10, 5 => 10, 21 => 0 }, :bad => {  }, :ordered => { }, :expected =>  0}, #10  XYZFIX P2
                  { :name => "copies 5", :custords => { 40 => 20}, :good => { 0 => 18,          21 => 0 }, :bad => {  }, :ordered => { }, :expected => 0},  #2   XYZFIX P2

                  # copies will be in stock soon, but they're bad
                  { :name => "bad 1", :custords => { 40 => 20}, :good => { },                            :bad => { 0 => 99  }, :ordered => { }, :expected => 7}, # 20
                  { :name => "bad 2", :custords => { 40 => 20}, :good => { },                            :bad => { 8 => 99  }, :ordered => { }, :expected => 7}, # 20

                  # we've already ordered copies
                  { :name =>"ordered 1", :custords => { 40 => 20}, :good => {  },                           :bad => {  }, :ordered => { 1 => 10 }, :expected => 0}, # 10
                  { :name =>"ordered 2", :custords => { 40 => 20}, :good => {  },                           :bad => {  }, :ordered => { 1 => 10, 5 => 10 }, :expected => 0},

                  # univ: we've got univ orders, and they're getting
                  # towards the end, and thus we need to actually buy
                  # DVDs
                  { :name => "univ 1",
                    :custords => { 0 => 0},
                    :univords => { 1 => 1, 2 => 1, 3=>3},  # 5 customers with low amounts of shippables left
                    :good => { 0 => 0, 5 => 0, 21 => 0 },
                    :bad => {  },
                    :ordered => { },
                    :expected => 1}, #5

                  # univ: we've got univ orders (but they've all got stuff in the field and nothing shippable)
                  # no copies to fill them with
                  { :name => "univ 2",
                    :custords => { 0 => 0},
                    :univords => { 90 => 5},  # 5 customers with lots of LIs left (no need to buy for them yet)
                    :good => { 0 => 0, 5 => 0, 21 => 0 },
                    :bad => {  },
                    :ordered => { },
                    :expected => 1}, # because we always want at least 1

                  # univ: we've got univ orders (but they've all got stuff in the field and nothing shippable)
                  # no copies to fill them with
                  { :name => "univ 3",
                    :custords => { 0 => 0},
                    :univords => { 5 => 5},  # 5 customers towards the end of their univ
                    :good => { 0 => 1 },  # 1 dvd in stock
                    :bad => {  },
                    :ordered => { },
                    :expected => 0},  # 5 - 1 = 4  # 4 XYZFIX P2

                  # univ / sf mixed
                  { :name => "univ / sf mixed",
                    :custords => { 1 => 1},           # 1 customer rented
                    :univords => { 5 => 5, 15 => 5},  # 5 uni custs of interest
                    :good => { 0 => 1 },  # 1 dvd in stock
                    :bad => {  },
                    :ordered => { },
                    :expected => 0}  # 6 - 1 = 5   # 5 XYZFIX P2

                 ]

    tt = products(:tobuy_title)
    test_array.each do |test|

#      puts "=======" + test[:name] 

      Copy.destroy_all
      LineItem.destroy_all
      VendorOrderLog.destroy_all
      InventoryOrdered.destroy_all

      setup_cust_orders(tt, test)
      setup_univ_orders(tt, test)
      setup_dvds_good(tt, test)
      setup_dvds_bad(tt, test)
      setup_vendor_orders(tt, test)

      # reload to get changes to inventoryordered, etc.
      tt.reload
      tt.update_tobuy
      tt.reload

      quant = tt.tobuy.nil? ?  0 : tt.tobuy.quant
      assert_equal(test[:expected], quant)

      # XYZFIX P4: test with hostile vendors
      # XYZFIX P4: test with bad copies delayed
      # XYZFIX P4: test with customer orders placed at various times

    end
  end

  def test_delay_calculations        
    Author.destroy_all
    Product.destroy_all
    Copy.destroy_all
    LineItem.destroy_all

    input = {
      :product_1 => {
        :in_field => [ 3 , 5 ],
        :good_copies  => 2,
        :bad_copies   => 0,
        :lis => [ (Date.today - 5), (Date.today - 2) ]
      },

        :product_univ => {
          :in_field => [ 3 , 5 ],
          :good_copies  => 0,
          :bad_copies   => 0,
           :lis => [ [ (Date.today - 5), true ], (Date.today - 2) ]
        },

        :product_no_copies => {
          :in_field => [  ],
          :good_copies  => 0,
          :bad_copies   => 0,
          :lis => [ [ (Date.today - 5), true ], (Date.today - 2) ]
        }
    }

    products = build_fake_products(input)


    #----------

    product = Product.find_by_name("product_1")
    product.update_product_delays
    assert_equal 0, product.get_delay(0)
    assert_equal 0, product.get_delay(1)
    assert_equal 16, product.get_delay(2)
    assert_equal 18, product.get_delay()

    #----------

    product = Product.find_by_name("product_univ")
    product.update_product_delays
    assert_equal 16, product.get_delay(0)
    assert_equal 18, product.get_delay(1)
    assert_equal 18, product.get_delay() 

    #----------
    product = Product.find_by_name("product_no_copies")
    product.update_product_delays

    assert_equal 1000, product.get_delay(0)
    assert_equal 1000, product.get_delay(1)
    assert_equal 1000, product.get_delay()

  end



end

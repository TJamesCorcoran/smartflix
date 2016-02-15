require 'test_helper'
require 'pp'

# We've got some helper methods (like build_fake()  ) in ../test/test_helper.rb that are helpful.
#


# In real production use, have a cache that tells us what LIs pt to gift certs.
# When we build fake LIs on the fly w fictional items, this breaks ... so override it.
class LineItem
  def isa_GiftCert?() product.name.match(/Gift/) end
end



class ShippingTest < ActiveSupport::TestCase
  
  # gets us country codes
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  

  
  def setup
    Shipping.logger = lambda { |x| }
    # Shipping.logger = method(:puts)   


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
  
  
  def test_makelist_giftcert_one                  
    setup
    
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "$10 Gift Cert", :giftCert => true } ]
        }
      }
    }
    
    build_fake(input)
    
    actual = Shipping.create_list
    
    customers = actual.keys
    cust_one_shipments = actual[customers.first]
    cust_one_items = cust_one_shipments.flatten
    
    assert_equal customers.size,          1, customers
    assert_equal cust_one_shipments.size, 1, cust_one_shipments
    assert_equal cust_one_items.size,     1, cust_one_items
    assert cust_one_items[0][:copy].is_a?(GiftCert) #, cust_one_items[0]
    
  end
  
  def test_makelist_giftcert_three                                     
    setup
    
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "$10 Gift Cert", :giftCert => true },
                    {:name => "$20 Gift Cert", :giftCert => true },
                    {:name => "$100 Gift Cert", :giftCert => true } ]
        }
      }
    }
    
    build_fake(input)
    
    actual = Shipping.create_list
    
    customers = actual.keys
    cust_one_shipments = actual[customers.first]
    cust_one_items = cust_one_shipments.flatten
    
    assert_equal customers.size,          1, customers
    assert_equal cust_one_shipments.size, 1, cust_one_shipments
    assert_equal cust_one_items.size,     3, cust_one_items
    assert cust_one_items[0][:copy].is_a?(GiftCert) #, cust_one_items[0]
    assert cust_one_items[1][:copy].is_a?(GiftCert) #, cust_one_items[0]
    assert cust_one_items[2][:copy].is_a?(GiftCert) #, cust_one_items[0]
    
  end
  
  def test_makelist_giftcert_and_copy                  
    setup
    
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "$10 Gift Cert", :giftCert => true },
                    {:name => "Some DVD Product", :inStock => true } ]
        }
      }
    }
    
    build_fake(input)
    
    actual = Shipping.create_list
    
    customers = actual.keys
    cust_one_shipments = actual[customers.first]
    cust_one_items = cust_one_shipments.flatten
    
    assert_equal customers.size,          1, customers
    assert_equal cust_one_shipments.size, 1, cust_one_shipments
    assert_equal cust_one_items.size,     2, cust_one_items
    
    assert cust_one_items[1][:copy].is_a?(GiftCert) #, cust_one_items[0]
    assert cust_one_items[0][:copy].is_a?(Copy)    # ,cust_one_items[1]
    
  end
  
  
  def test_makepotential_giftcert_and_copy                                     
    setup
    
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "$10 Gift Cert", :giftCert => true },
                    {:name => "Some DVD Product", :inStock => true } ]
        }
      }
    }
    
    build_fake(input)
    
    new_shipments = Shipping.create_list
    Shipping.save_to_db(new_shipments)
    
    shipments = PotentialShipment.find(:all)
    items = PotentialItem.find(:all)
    
    assert_equal shipments.size,          1, shipments
    assert_equal items.size, 2, items
    assert items[0].is_a?(PotentialCopy),     items[0]
    assert items[1].is_a?(PotentialGiftCert), items[1]
    
    assert_equal items[0].copy.product.name, "Some DVD Product"
    assert_equal items[1].gift_cert.name, "$10 Gift Cert"
    
  end
  
  
  def test_dont_ship_nonactionable                                    
    setup
    
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "late charge",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true, :actionable => false} ]
        }
      },
      :cust2 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart11", :inStock => true} ]
        }
      }
    }
    build_fake(input)
    actual = Shipping.create_list
    
    cust1 = txt2cust(:cust1)
    cust2 = txt2cust(:cust2)
    
    golden_1 = nil
    golden_2 = ["smart11"]
    
    products_for_cust1 = actual[cust1]
    products_for_cust2 = actual[cust2].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    
    
    assert_equal(golden_1,    products_for_cust1)
    assert_equal(golden_2,    products_for_cust2)
  end
  
  def test_potential_shipments_pt_to_lis                                    
    setup
    
    input =  { 
      :cust1 => {
        :original_order => { 
          :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true, :actionable => true, :dateOut => Date.today - 90, :dateBack => Date.today - 50}]
        },
        :sf_late_1 => {
          :orderDate => Date.today - 80,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true, :actionable => false } ]
        },
        :sf_late_2 => {
          :orderDate => Date.today - 70,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true, :actionable => false } ]
        },
        :sf_late_3 => {
          :orderDate => Date.today - 60,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true, :actionable => false } ]
        },
        :re_order => { 
          :orderDate => Date.today,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true, :actionable => true } ]
        }
      }
    }
    
    build_fake(input)
    actual = Shipping.create_list
    Shipping.save_to_db(actual)
    
    # sanity check
    cust1 = txt2cust(:cust1)
    golden_1 = ["smart10"]
    products_for_cust1 = actual[cust1].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    assert_equal(golden_1,    products_for_cust1)
    
    # OK, now the meat of the matter:
    # we want to make sure that the PotentialItem points to the LineItem that
    # gave rise to it.
    
    recent_order_li = Order.find_by_orderDate(Date.today).line_items.first
    ps = PotentialShipment.find(:all).first
    pi = PotentialItem.find(:all).first
    
    assert_equal(recent_order_li, pi.line_item)
    
    # now reify the potential shipment
    Shipping.make_potential_shipment_real(ps)
    recent_order_li.reload
    
    assert_equal(0, PotentialShipment.count)
    assert(recent_order_li.copy)
    assert_equal(0, recent_order_li.copy.inStock)
    assert_equal(Date.today, recent_order_li.dateOut)    
  end


  def test_ship_sets_in_order                
    setup
    
    input =  { 
      :cust1 => {
        :order_a => { 
          :orderDate => Date.today,
          :paid => true,
          :lis => [ {:name => "uuu1", :inStock => false, :actionable => true},
                    {:name => "uuu2", :inStock => true, :actionable => true},
                  ]
        }
      },

      :cust2 => {
        :order_b => { 
          :orderDate => Date.today,
          :paid => true,
          :lis => [ {:name => "ooo1", :inStock => false, :actionable => true},
                    {:name => "ooo2", :inStock => true, :actionable => true},
                  ]
        }
      }
    }

    build_fake(input)

    #----------
    # create sets
    unordered_set = ProductSet.create!
    unordered_set.add_product(Product.find_by_name("uuu1"), 1)
    unordered_set.add_product(Product.find_by_name("uuu2"), 2)

    ordered_set = ProductSet.create!(:order_matters => true)
    ordered_set.add_product(Product.find_by_name("ooo1"), 1)
    ordered_set.add_product(Product.find_by_name("ooo2"), 2)

    #----------
    # do calculation
    actual = Shipping.create_list
    Shipping.save_to_db(actual)
    
    #----------
    # test
    cust1 = txt2cust(:cust1)
    golden_1 = ["uuu2"]
    products_for_cust1 = actual[cust1].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    assert_equal(golden_1,    products_for_cust1)

    cust2 = txt2cust(:cust2)
    golden_2 = []
    products_for_cust2 = actual[cust2].to_array.flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    assert_equal(golden_2,    products_for_cust2)

    
  end
  
  # Once we find all the paid-up orders, we assign copies to EVERY lineitem.
  # 
  # ...then we prune down the orders to just ship a sane amount (where
  # "sane" is defined differently for univs, regular orders, etc.)
  # 
  # This tests the pruning.
  #
  def test_prune_for_throttling                  
    setup
    
    univ = University.create(:name => "woodturning", :category_id => 1)
    
    input =  { :cust1 => { :in_field => {},
        :wood_order => { :orderDate => Date.today - 7,
          :server_name => "woodturning",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true}]
        },
        :sf_order_1 => { :orderDate => Date.today - 3,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [  {:name => "smart10", :inStock => true},
                     {:name => "smart11", :inStock => true},
                     {:name => "smart12", :inStock => true}]
        },
        :sf_order_2 => { :orderDate => Date.today - 3,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [  {:name => "smart20", :inStock => true},
                     {:name => "smart21", :inStock => true},
                     {:name => "smart22", :inStock => true},
                     {:name => "smart23", :inStock => true}]
        }
      } # cust1
    } # all custs
    build_fake(input)
    
    cust = txt2cust(:cust1)
    
    already_allocated_li_co_pairs = [ { :co => txt2co("wood1"), :li => txt2li("wood1") },
                                      { :co => txt2co("wood2"), :li => txt2li("wood2") },
                                      { :co => txt2co("wood3"), :li => txt2li("wood3") },
                                      { :co => txt2co("smart10"), :li => txt2li("smart10") },
                                      { :co => txt2co("smart11"), :li => txt2li("smart11") },
                                      { :co => txt2co("smart11"), :li => txt2li("smart11") },
                                    ]
    
    li_copy_pairs =                 [ { :co => txt2co("smart20"), :li => txt2li("smart20") },
                                      { :co => txt2co("smart21"), :li => txt2li("smart21") },
                                      { :co => txt2co("smart22"), :li => txt2li("smart22") },
                                      { :co => txt2co("smart23"), :li => txt2li("smart23") },
                                    ]
    post_pruned = Shipping.prune_for_throttling(cust, li_copy_pairs, already_allocated_li_co_pairs)
    post_pruned_products = post_pruned.map{ |pair| pair[:co].product.name}
    
    golden = ["smart20"]
    actual = post_pruned_products
    
    assert_equal(golden.to_set, actual.to_set, "3 prev items from SF should count against current load to SF")
  end

  # Univ customers can reorder their line items, by changing the queue_position on each.
  # We always want to ship the lowest queue items.
  #
  # This tests that.
  #
  def test_sorting_univ_lis
    setup
    
    univ = University.create(:name => "woodturning", :category_id => 1)
    
    input =  { :cust1 => { :in_field => {},
        :wood_order => { :orderDate => Date.today - 7,
          :server_name => "woodturning",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood5", :inStock => true, :queue_position => 5},
                    {:name => "wood3", :inStock => false, :queue_position => 3},    # NOTE - OOS!
                    {:name => "woodNIL", :inStock => true, :queue_position => nil}, # NOTE - nil!
                    {:name => "wood4", :inStock => true, :queue_position => 4},
                    {:name => "wood2", :inStock => true, :queue_position => 2},
                    {:name => "wood1", :inStock => true, :queue_position => 1} ]
        },
      } # cust1
    } # all custs
    build_fake(input)

    new_shipments = Shipping.create_list

    cust1 = txt2cust(:cust1)

    shipments = new_shipments[cust1]

    assert_equal(1, shipments.size)

    coli_pairs = shipments.first
    assert_equal(3, coli_pairs.size)

    lis = coli_pairs.map{ |hh| hh[:li]}
    copies = coli_pairs.map{ |hh| hh[:copy]}

    assert_equal([1,2,4].to_set, lis.map(&:queue_position).to_set)
    assert_equal(["wood1","wood2","wood4"].to_set, copies.map(&:name).to_set)
    


  end

  
  def test_shippable_count_for_univ_month_live_bit()         
    setup
    
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { :cust1 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 2, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true} ]
        }
      },  # cust1

 :cust2 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :live => false,
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 2, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true} ]
        }
      } # cust2
    } # all custs

    build_fake(input)

    cust1 = txt2cust(:cust1)
    cust2 = txt2cust(:cust2)


    assert_equal(3, cust1.shippable_count_for_univ(univ, 0))
    assert_equal(0, cust2.shippable_count_for_univ(univ, 0))
    
  end

  # What if a customer has two of the same univ order, one live, one dead?
  # 
  # On 17 Mar 2011 this was discovered to be a Charlie Foxtrot - we keep shipping infinite disks!
  #
  def test_shippable_count_for_univ_month_live_bit_double()         
    setup
    
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { :cust1 => { :in_field => { "wood" => 3}, 
                           :wood => { :orderDate => Date.today - 60,
                                      :server_name => "wood",
                                      :live => false,                    # <---- FALSE
                                      :univ_dvd_rate => 3,
                                      :payments => [ { :date=> Date.today - 2, :complete => true, :successful => true } ],
                                      :lis => [ {:name => "wood1", :inStock => true},
                                                {:name => "wood2", :inStock => true},
                                                {:name => "wood3", :inStock => true},
                                                {:name => "wood4", :inStock => true},
                                                {:name => "wood5", :inStock => true},
                                                {:name => "wood6", :inStock => true} ] },
        
                           :wood_2 => { :orderDate => Date.today - 60,
                                        :server_name => "wood",
                                        :live => true,                    # <---- TRUE
                                        :univ_dvd_rate => 3,
                                        :payments => [ { :date=> Date.today - 2, :complete => true, :successful => true } ],
                                        :lis => [ {:name => "wood1", :inStock => true},
                                                  {:name => "wood2", :inStock => true},
                                                  {:name => "wood3", :inStock => true},
                                                  {:name => "wood4", :inStock => true},
                                                  {:name => "wood5", :inStock => true},
                                                  {:name => "wood6", :inStock => true} ]  }
      } # cust2
    } # all custs

    build_fake(input)
    
    cust1 = txt2cust(:cust1)

    # hack: all of the in-field line items are on first (dead) order,
    # and we want to move them to the live order

    live = cust1.orders.select(&:live).first
    dead = cust1.orders.reject(&:live).first

    # puts "live:    #{live.inspect}"
    # puts "dead:    #{dead.inspect}"
    # puts "live field count:    #{live.line_items_in_field.size}"
    # puts "dead field count:    #{dead.line_items_in_field.size}"

    cust1.lis_in_field.each { |li| li.update_attributes(:order => live) }

    # puts "----------"
    # puts "live field count:    #{live.line_items_in_field.size}"
    # puts "dead field count:    #{dead.line_items_in_field.size}"

    # check that our hack worked
    assert_equal(0, dead.line_items_in_field.size)
    assert_equal(3, live.line_items_in_field.size)

    # the actual test
    assert_equal(0, cust1.shippable_count_for_univ(univ, 0))
    
  end



  def test_shippable_count_for_univ_month_1()                                     
    setup
    
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { :cust1 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 2, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true} ]
        }
      } # cust1
    } # all custs
    customer = build_fake(input).first
    assert_equal(3, customer.shippable_count_for_univ(univ, 0))
    
  end
  
  def test_shippable_count_for_univ_month_2_2_returned()                                     
    setup
    
    univ = University.create(:name => "wood", :category_id => 1)
    input =  { :cust1 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 45, :complete => true, :successful => true },
                         { :date=> Date.today - 15, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true, :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)},
                    {:name => "wood2", :inStock => true, :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)},
                    {:name => "wood3", :inStock => true, :dateOut => (Date.today - 40)},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true} ]
        }
      } # cust1
    } # all custs
    customer = build_fake(input).first
    assert_equal(2, customer.shippable_count_for_univ(univ, 0))
    
  end
  

  
  def test_orders_being_partially_shipped_today            
    setup
    
    wood_univ  = University.create(:name => "wood", :category_id => 1)
    metal_univ = University.create(:name => "metal", :category_id => 2)
    plastic_univ = University.create(:name => "plastic", :category_id => 3)

    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 9,     # ship 2 of these
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => false},
                    {:name => "smart11", :inStock => true},
                    {:name => "smart12", :inStock => true} ]
        }
      }, # cust1
      :cust2 => {
        :sf_order_1 => { :orderDate => Date.today - 8,  # ship ? of these
          :server_name => "smartflix",
          :paid => true,        
          :lis => [ {:name => "smart20", :inStock => true},
                    {:name => "smart21", :inStock => true},
                    {:name => "smart22", :inStock => false} ]
        },
        :sf_order_2 => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart23", :inStock => false},
                    {:name => "smart24", :inStock => false},
                    {:name => "smart25", :inStock => false} ]
        },
        :wood_order => { :orderDate => Date.today - 6,  # ship some items!
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood1", :inStock => false},
                    {:name => "wood2", :inStock => false},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true}  ]
        },
        :plastic_order => { :orderDate => Date.today - 5,
          :server_name => "plastic",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "plastic1", :inStock => false},
                    {:name => "plastic2", :inStock => false}  ]
        }
      }
    }
    
    build_fake(input)
    
    # cust1 --> :sf_order    yes, 2 items going out today
    # cust2 --> :sf_order_1  yes, 1 item  going out today
    #           :sf_order_2  no,  0 items going out today
    #           :wood_order  yes, 3 items going out today
    #           :plastic...  no,  0 items going out today
    #
    expected = [ txt2li("smart10").order,
                 txt2li("smart20").order,
                 txt2li("wood1").order ]

    @new_shipments = Shipping.create_list

    PotentialShipment.destroy_all
    PotentialItem.destroy_all
    Shipping.save_to_db(@new_shipments)

    actual = Shipping.orders_being_partially_shipped_today

    assert_equal(expected.to_set, actual.to_set)
    
    # inverse of above
    #
    #
    expected_unshippable = [ txt2li("smart23").order, txt2li("plastic1").order ]
    actual_unshippable = Shipping.unshippable_oos
    assert_equal(expected_unshippable.map(&:id).to_set, actual_unshippable.map(&:id).to_set)
    
    # now the reporting aspect ... prunes off the university, bc we don't report on that
    #
    expected_worth_reporting = [ txt2li("smart23").order ]
    actual_worth_reporting = Shipping.unshippable_oos_mention
    assert_equal(expected_worth_reporting.map(&:id).to_set, actual_worth_reporting.map(&:id).to_set)
    
    # hack one order; test it again
    txt2li("smart23").order.update_attributes(:unshippedMsgSentP => true)
    expected_worth_reporting = [ ]
    actual_worth_reporting = Shipping.unshippable_oos_mention
    assert_equal(expected_worth_reporting.map(&:id).to_set, actual_worth_reporting.map(&:id).to_set)
    
  end

  # As per the comment in file
  #     lib/shipping.rb
  # for func
  #     unshippable_oos_mention
  # we don't want to report very recent orders from the OOS report
  #
  def test_that_we_dont_report_oos_for_todays_orders          
    setup
    
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => false},
                    {:name => "smart11", :inStock => false},
                    {:name => "smart12", :inStock => false} ]
        }
      },
      :cust2 => {
        :sf_order => { :orderDate => Date.today,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart99", :inStock => true} ]
        }
      }
     }

    # orders placed today should not report OOS
    #
    build_fake(input)
    PotentialShipment.destroy_all
    PotentialItem.destroy_all
    new_shipments = Shipping.create_list
    Shipping.save_to_db(new_shipments)

    actual = Shipping.unshippable_oos_mention
    expected = [ ]
    assert_equal(expected.to_set, actual.to_set)

    # orders placed yesterday SHOULD report OOS
    #
    #  (we can delete and recreate the potential shipments here if we
    #   want, it won't make a difference)

    Date.force_today(Date.today + 1)

    actual = Shipping.unshippable_oos_mention

    expected = [txt2cust(:cust1).orders.first ]
    assert_equal(expected.to_set, actual.to_set)



    Date.force_today(nil)

  end
  
  
  
  def test_create_list_double_sf()                                     
    setup
    
    #----------
    # make sure that two orders from SF don't result in exceeding the threshold
    #
    input =  { :cust1 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart1", :inStock => true},
                    {:name => "smart2", :inStock => true},
                    {:name => "smart3", :inStock => true},
                    {:name => "smart4", :inStock => true}]
        },
        :sf_order_2 => { :orderDate => Date.today - 3,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true},
                    {:name => "smart11", :inStock => true},
                    {:name => "smart12", :inStock => true},
                    {:name => "smart13", :inStock => true}]
        } 
      } 
    } # all custs
    build_fake(input)
    cust1 = txt2cust(:cust1)
    list = Shipping.create_list
    products_for_cust1 = list[cust1].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    
    golden = ["smart1", "smart2", "smart3", "smart4" ]
    actual = products_for_cust1
    
    assert_equal(golden.to_set, actual.to_set, "don't let 2 orders exceed throttle")
    
  end
  
  # only ship items that have been paid for
  def test_unpaid()            
    setup
    
    input =  { 
      :cust1 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix.com",
          :payments => [ { :date=> Date.today - 2, 
                           :complete => true, 
                           :successful => false,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :inStock => true},
                    {:name => "smart2", :inStock => true},
                    {:name => "smart3", :inStock => true},
                    {:name => "smart4", :inStock => true}]
        },
      },
      :cust2 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix.com",
          :payments => [ { :date=> Date.today - 2, 
                           :complete => true, 
                           :successful => true,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :inStock => true},
                    {:name => "smart2", :inStock => true},
                    {:name => "smart3", :inStock => true},
                    {:name => "smart4", :inStock => true}]
        },
      },
      :cust3 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "backend",
          :payments => [  ],
          :lis => [ {:name => "backend1", :inStock => true}]
        },
      } 
    } # all custs

    build_fake(input)
    list = Shipping.create_list

    cust1 = txt2cust(:cust1)
    cust2 = txt2cust(:cust2)
    cust3 = txt2cust(:cust3)



    # cust 1 did not pay,  he gets nothing
    actual = list[cust1]
    golden = nil
    assert_equal(golden, actual)

    # cust 2 did pay,  he gets dvds
    actual = list[cust2].flatten.map{ |coli_pair| coli_pair[:copy].product.name}.to_set
    golden = ["smart1", "smart2", "smart3", "smart4"].to_set
    assert_equal(golden, actual)

    # cust 3 did not pay, but it's a backend order, so he gets dvds
    actual = list[cust3].flatten.map{ |coli_pair| coli_pair[:copy].product.name}.to_set
    golden = ["backend1"].to_set
    assert_equal(golden, actual)
    
  end
  

  # don't ship an item unless its precond has already shipped
  def test_precond_pruning()                  
    setup
    
    input =  { 
      :cust1 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "wood1", :inStock => false},
                    {:name => "wood2", :inStock => true},
                    
                    {:name => "bone1", :inStock => true},
                    {:name => "bone2", :inStock => true}]
        },
      },
    } # all custs
    build_fake(input)
    
    wood1 = txt2tit( "wood1")
    wood2 = txt2tit( "wood2")
    
    pset = ProductSet.create!(:name => "wood set", :order_matters => true)
    pset.add_product(wood1, 1)
    pset.add_product(wood2, 2)
    
    wood2.reload
    
    cust1 = txt2cust(:cust1)
    
    list = Shipping.create_list
    actual = list[cust1].flatten.map{ |coli_pair| coli_pair[:copy].product.name}.to_set
    
    golden = ["bone1", "bone2" ].to_set
    assert_equal(golden, actual)
    
  end


  def test_create_list_sf_univ()       
    setup
    
    
    #----------
    # Make sure that a univ sub and a SF order both ship items 
    # 
    # * neither order should overwrite the other
    # * the shipping limits are independent
    #
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { :cust2 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart20", :inStock => true},
                    {:name => "smart21", :inStock => true} ]
        },
        :wood_univ_order => { :orderDate => Date.today - 7,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true}  ]
        } # univ-order
      } # cust1
    } # all custs
    build_fake(input)
    cust = txt2cust(:cust2)
    wood_order = cust.orders.select { |o| o.university == univ }

    list = Shipping.create_list
    products_for_cust2 = list[cust].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    
    
    golden = ["smart20", "smart21", "wood1", "wood2", "wood3"]
    actual = products_for_cust2
    
    assert_equal(golden.to_set, actual.to_set)
    
  end
  
  
  # just like test_shippable_count_for_univ_month_2_2_returned, but we set the ignore_for_univ_limits bit on one of the in-field dvds 
  def test_shippable_count_for_univ_month_2_2_returned_1_doesnt_count()                                     
    setup
    
    univ = University.create(:name => "wood", :category_id => 1)
    input =  { :cust1 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 45, :complete => true, :successful => true },
                         { :date=> Date.today - 15, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true, :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)},
                    {:name => "wood2", :inStock => true, :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)},
                    {:name => "wood3", :inStock => true, :dateOut => (Date.today - 40), :ignore_for_univ_limits => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true} ]
        }
      } # cust1
    } # all custs
    customer = build_fake(input).first
    assert_equal(3, customer.shippable_count_for_univ(univ, 0))
    
  end
  
  
  # Univ shipments sometimes get lost, and we send out replacements.
  #
  # We don't want these replacements to count against the monthly
  # limit, so we mark these replcaement LIs "ignore_for_univ_limits".
  #
  # Verify that this mechanism works:
  #   * place two orders.  One has just regular univ LIs, one has "ignore" LIs.
  #   * make sure that:
  #        * we ship the right number of the regular ones 
  #        * ALL of the replacement ones
  #
  def test_shippable_count_ignore_for_univ()                  
    setup
    
    [ { :univ_dvd_rate => 3, 
        :golden => ["wood1", "wood2", "wood3", "wood11", "wood13", "wood14", "wood15", "wood16"] },
      { :univ_dvd_rate => 6, 
        :golden => ["wood1", "wood2", "wood3", "wood4", "wood5", "wood6", "wood11", "wood13", "wood14", "wood15", "wood16"] }
      
    ].each do |test_hash|
      
      dvd_rate = test_hash[:univ_dvd_rate]
      golden = test_hash[:golden]
      
      setup
      univ = University.create(:name => "wood", :category_id => 1)
      input =  { :cust1 => { :wood => { :orderDate => Date.today - 15,
            :server_name => "wood",
            :univ_dvd_rate => dvd_rate,
            :payments => [ { :date=> Date.today - 15, :complete => true, :successful => true } ],
            :lis => [ {:name => "wood1", :inStock => true},
                      {:name => "wood2", :inStock => true},
                      {:name => "wood3", :inStock => true},
                      {:name => "wood4", :inStock => true},
                      {:name => "wood5", :inStock => true},
                      {:name => "wood6", :inStock => true} ]
          },
          :wood_2 => { :orderDate => Date.today - 2,
            :server_name => "wood",
            :univ_dvd_rate => dvd_rate, # should be ignored
            :payments => [ { :date=> Date.today - 15, :complete => true, :successful => true } ],
            :lis => [ {:name => "wood10", :inStock => false,:ignore_for_univ_limits => true},
                      {:name => "wood11", :inStock => true, :ignore_for_univ_limits => true},
                      {:name => "wood12", :inStock => false,:ignore_for_univ_limits => true},
                      {:name => "wood13", :inStock => true, :ignore_for_univ_limits => true},
                      {:name => "wood14", :inStock => true, :ignore_for_univ_limits => true},
                      {:name => "wood15", :inStock => true, :ignore_for_univ_limits => true},
                      {:name => "wood16", :inStock => true, :ignore_for_univ_limits => true}]
          }
        } # cust1
      } # all custs
      build_fake(input).first
      
      list = Shipping.create_list
      cust1 = txt2cust(:cust1)
      products_for_cust1 = list[cust1].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
      
      assert_equal(golden.to_set, products_for_cust1.to_set)
    end
    
    
  end
  
  def test_shippable_count_for_univ_month_2_0_returned()                                     
    setup
    
    #----------
    # Make sure that a univ sub and a SF order both ship items 
    # 
    # * neither order should overwrite the other
    # * the shipping limits are independent
    #
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { :cust1 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 45, :complete => true, :successful => true },
                         { :date=> Date.today - 15, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true, :dateOut => (Date.today - 40)},
                    {:name => "wood2", :inStock => true, :dateOut => (Date.today - 40)},
                    {:name => "wood3", :inStock => true, :dateOut => (Date.today - 40)},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true} ]
        }
      } # cust1
    } # all custs
    customer = build_fake(input).first
    assert_equal(0, customer.shippable_count_for_univ(univ, 0))
    
  end
  
  
  
  # In Aug 2009 we started support multiple subscription sizes
  # Make sure that it works
  def test_var_univ_size___shippable_count()                             
    setup
    
    #----------
    # Make sure that a univ sub and a SF order both ship items 
    # 
    # * neither order should overwrite the other
    # * the shipping limits are independent
    #
    univ = University.create(:name => "wood", :category_id => 1, :subscription_charge => 10.0)
    
    input =  {
      :cust_3 => { :wood => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood8", :inStock => true},
                    {:name => "wood9", :inStock => true}, 
                    {:name => "wood10", :inStock => true},
                  ]
        }
      }, 
      
      :cust_6 => { :wood => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood8", :inStock => true},
                    {:name => "wood9", :inStock => true}, 
                    {:name => "wood10", :inStock => true},
                  ]
        }
      },
      
      :cust_8 => { :wood => { :orderDate => Date.today - 60,
          :server_name => "wood",
          :univ_dvd_rate => 8,
          :payments => [ { :date=> Date.today - 15, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood8", :inStock => true},
                    {:name => "wood9", :inStock => true}, 
                    {:name => "wood10", :inStock => true},
                  ]
        }
      }
    } # all custs
    
    build_fake(input)
    
    cust3 = txt2cust(:cust_3)
    cust6 = txt2cust(:cust_6)
    cust8 = txt2cust(:cust_8)
    
    assert_equal(3, cust3.shippable_count_for_univ(univ, 0))
    assert_equal(6, cust6.shippable_count_for_univ(univ, 0))
    assert_equal(8, cust8.shippable_count_for_univ(univ, 0))
  end
  
  def test_var_univ_size___actually_shipping()                            
    setup
    #----------
    # Make sure that a univ sub and a SF order both ship items 
    # 
    # * neither order should overwrite the other
    # * the shipping limits are independent
    #
    univ = University.create(:name => "wood", :category_id => 1, :subscription_charge => 10.0)
    
    
    input =  {
      :cust_6b => { :wood => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood1", :inStock => true},
                    {:name => "wood2", :inStock => true},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood6", :inStock => true},
                    {:name => "wood8", :inStock => true},
                    {:name => "wood9", :inStock => true}, 
                    {:name => "wood10", :inStock => true},
                  ]
        },
        :wood_replacement => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood11", :inStock => true, :ignore_for_univ_limits => true}
                  ]
        }
      },
      
      :cust_6c => { :wood => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood101", :inStock => true},
                    {:name => "wood102", :inStock => true},
                    {:name => "wood103", :inStock => true},
                    {:name => "wood104", :inStock => true},
                    {:name => "wood105", :inStock => true},
                    {:name => "wood106", :inStock => true},
                    {:name => "wood106", :inStock => true},
                    {:name => "wood108", :inStock => true},
                    {:name => "wood109", :inStock => true}, 
                    {:name => "wood110", :inStock => true},
                  ]
        },
        :wood_replacement => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood111", :inStock => true, :ignore_for_univ_limits => true},
                    {:name => "wood112", :inStock => true, :ignore_for_univ_limits => true}
                  ]
        }
      },
      
      :cust_8b => { :wood => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 8,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood201", :inStock => true},
                    {:name => "wood202", :inStock => true},
                    {:name => "wood203", :inStock => true},
                    {:name => "wood204", :inStock => true},
                    {:name => "wood205", :inStock => true},
                    {:name => "wood206", :inStock => true},
                    {:name => "wood206", :inStock => true},
                    {:name => "wood208", :inStock => true},
                    {:name => "wood209", :inStock => true}, 
                    {:name => "wood210", :inStock => true},
                  ]
        },
        :wood_replacement_a => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood211", :inStock => true, :ignore_for_univ_limits => true},
                  ]
        },
        :wood_replacement_b => { :orderDate => Date.today - 1,
          :server_name => "wood",
          :univ_dvd_rate => 6,
          :payments => [ { :date=> Date.today - 1, :complete => true, :successful => true } ],
          :lis => [ {:name => "wood212", :inStock => true, :ignore_for_univ_limits => true},
                    {:name => "wood213", :inStock => true, :ignore_for_univ_limits => true}
                  ]
        }
      }
    }
    
    
    build_fake(input)
    
    
    cust6b = txt2cust(:cust_6b)
    cust6c = txt2cust(:cust_6c)
    cust8b = txt2cust(:cust_8b)
    
    
    list = Shipping.create_list
    
    
    assert_equal(6, cust6b.shippable_count_for_univ(univ, 0))
    assert_equal(7, list[cust6b].flatten.size)
    
    assert_equal(8, list[cust6c].flatten.size)
    
    assert_equal(11, list[cust8b].flatten.size)
    
    
  end
  
  
  def test_create_list_bigtest()                    
    setup
    
    
    #----------
    # cust 1 has 1 SF orders + some in field
    # cust 2 has 3 SF + 2 univ (1 of SF is OOS, 2 of each univ is OOS) + 2 wood in field
    # cust 3 has 1 SF + 1 univ 
    # 
    wood_univ  = University.create(:name => "wood", :category_id => 1)
    
    metal_univ = University.create(:name => "metal", :category_id => 2)
    
    input =  { 
      :cust1 => { :in_field => { "smartflix" => 2},
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart10", :inStock => true},
                    {:name => "smart11", :inStock => true},
                    {:name => "smart12", :inStock => true} ]
        }
      }, # cust1
      
      :cust2 => { 
        :in_field => { "wood" => 2},
        :sf_order_1 => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart20", :inStock => true},  #ship the instocks
                    {:name => "smart21", :inStock => true},
                    {:name => "smart22", :inStock => false} ]
        },
        :sf_order_2 => { :orderDate => Date.today - 6,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart23", :inStock => true}, #ship the instocks
                    {:name => "smart24", :inStock => true},
                    {:name => "smart25", :inStock => false} ]
        },
        :sf_order_3 => { :orderDate => Date.today - 5,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart26", :inStock => true}, 
                    {:name => "smart27", :inStock => true},
                    {:name => "smart28", :inStock => false} ]
        },
        :wood_order => { :orderDate => Date.today - 7,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood1", :inStock => false},
                    {:name => "wood2", :inStock => false},
                    {:name => "wood3", :inStock => true},
                    {:name => "wood4", :inStock => true},
                    {:name => "wood5", :inStock => true},
                    {:name => "wood6", :inStock => true}  ]
        },
        :metal_order => { :orderDate => Date.today - 7,
          :server_name => "metal",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "metal1", :inStock => false},
                    {:name => "metal2", :inStock => false},
                    {:name => "metal3", :inStock => true},
                    {:name => "metal4", :inStock => true},
                    {:name => "metal5", :inStock => true},
                    {:name => "metal6", :inStock => true},
                    {:name => "metal7", :inStock => true}  ]
        }
      }, # cust2
      :cust3 => { :in_field => { "smartflix" => 2},
        :sf_order_1 => { :orderDate => Date.today - 2,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "smart20", :inStock => true} ]
        },
        :metal_order => { :orderDate => Date.today - 2,
          :server_name => "metal",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "metal1", :inStock => false},
                    {:name => "metal2", :inStock => false},
                    {:name => "metal3", :inStock => true},
                    {:name => "metal4", :inStock => true},
                    {:name => "metal5", :inStock => true},
                    {:name => "metal6", :inStock => true},
                    {:name => "metal7", :inStock => true}  ]
        }
      }
    }
    
    build_fake(input)
    cust1 = txt2cust(:cust1)
    cust2 = txt2cust(:cust2)
    cust3 = txt2cust(:cust3)
    
    list = Shipping.create_list

    if true
      products_for_cust1 = list[cust1].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
      cust1_golden = ["smart10", "smart11"]
      assert_equal(cust1_golden.to_set, products_for_cust1.to_set)
    end
    
    products_for_cust2 = list[cust2].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
    cust2_golden = ["smart20", "smart21", "smart23", "smart24",
                    "wood3", #  "wood4", "wood5", 
                    "metal3", "metal4", "metal5"]
    assert_equal(cust2_golden.sort, products_for_cust2.sort)
    
    if true
      # no SF - all are out with cust2!
      # metal 1,2 are OOS
      # metal 3,4,5 are oit with cust2
      products_for_cust3 = list[cust3].flatten.map{ |coli_pair| coli_pair[:copy].product.name}
      cust3_golden = ["metal6", "metal7"]
      assert_equal(cust3_golden.to_set, products_for_cust3.to_set)
    end
    
    
  end
  
  
end

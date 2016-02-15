require 'test_helper'

class UniversityTest < ActiveSupport::TestCase
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def test_subscription_charge

    puts "Rails.env = #{Rails.env}"

    Author.destroy_all
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all

    # setup
    #
    author = Author.create!(:name => "various")
    wood_cat = Category.create!(:description => "wood cat", :parent_id => 0)
    wood_univ = University.create_new(:name => "wood",
                                      :domains => [],
                                      :title_id_list =>  [ Product.create!(:name => "wood1", :description=>"foo", :date_added => Date.today, :purchase_price => 40, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                           Product.create!(:name => "wood2", :description=>"foo", :date_added => Date.today, :purchase_price => 50, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                           Product.create!(:name => "wood3", :description=>"foo", :date_added => Date.today, :purchase_price => 60, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id],
                                      :category => wood_cat)
    wood_univ.subscription_charge = 22.95
    wood_univ.save!



    oil_cat = Category.create!(:description => "oil cat", :parent_id => 0)
    oil_univ = University.create_new(:name => "oil uni",
                                      :domains => [],
                                      :title_id_list =>  [ Product.create!(:name => "oil1", :description=>"foo", :date_added => Date.today, :purchase_price => 40, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                           Product.create!(:name => "oil2", :description=>"foo", :date_added => Date.today, :purchase_price => 50, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                           Product.create!(:name => "oil3", :description=>"foo", :date_added => Date.today, :purchase_price => 60, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id],
                                      :category => oil_cat)
    oil_univ.subscription_charge = 25.95
    oil_univ.save!


    assert_equal(22.95, wood_univ.subscription_charge_for_n(3))
    assert_equal(36.72, wood_univ.subscription_charge_for_n(6))
    assert_equal(42.92, wood_univ.subscription_charge_for_n(8))
    # illegal amount
    error_thrown = false
    begin 
      wood_univ.subscription_charge_for_n(9000)
    rescue
      error_thrown = true
    end
    assert_equal(true, error_thrown)


    assert_equal( 3, wood_univ.number_per_month(BigDecimal("11.48")))
    assert_equal( 3, wood_univ.number_per_month(BigDecimal("22.95")))
    assert_equal( 6, wood_univ.number_per_month(BigDecimal("36.72")))
    assert_equal( 8, wood_univ.number_per_month(BigDecimal("42.92")))

    assert_equal( 3, oil_univ.number_per_month(BigDecimal("12.98")))
    assert_equal( 3, oil_univ.number_per_month(BigDecimal("25.95")))
    assert_equal( 6, oil_univ.number_per_month(BigDecimal("41.52")))
    assert_equal( 8, oil_univ.number_per_month(BigDecimal("48.53")))

    
    # illegal amount
    error_thrown = false
    begin 
      wood_univ.number_per_month(123.45)
    rescue
      error_thrown = true
    end
    assert_equal(true, error_thrown)

  end
  
  def test_add_remove_product
    Author.destroy_all
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all

    # setup
    #
    author = Author.create!(:name => "various")
    wood_cat = Category.create!(:description => "wood cat", :description =>"foo", :parent_id => 0)
    wood_univ = University.create_new(:name => "wood",
                                      :domains => [],
                                      :title_id_list =>  [ Product.create!(:name => "wood1", :description=>"foo", :date_added => Date.today, :purchase_price => 40, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                           Product.create!(:name => "wood2", :description=>"foo", :date_added => Date.today, :purchase_price => 50, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                           Product.create!(:name => "wood3", :description=>"foo", :date_added => Date.today, :purchase_price => 60, :categories => [ wood_cat ], :author_id => 1, :vendor_id =>1).id],
                                      :category => wood_cat)
    input =  { 
      # customer's university order is done.  
      :cust1 => {
        :wood_order => { :orderDate => Date.today - 50,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood1", :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)},
                    {:name => "wood2", :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)},
                    {:name => "wood3", :dateOut => (Date.today - 40), :dateBack => (Date.today - 20)} ]
        }
      },
      
      # customer's university order is live.  
      :cust2 => {
        :wood_order => { :orderDate => Date.today - 50,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "wood1" },
                    {:name => "wood2" },
                    {:name => "wood3" } ]
        }
      }
      
    }
    
    build_fake(input)
    wood_univ.reload

    # add a product.  Should be added to univ and to cust2's order.
    #

    univ_size_before = wood_univ.products.size
    new_product = Product.create!(:name => "new product", :description=>"foo", :date_added => Date.today, :purchase_price => 123, :vendor_id => 1, :author_id => 1, :categories => [Category.create!(:parent_id => 0, :description =>"foo" )])
    wood_univ.add_product(new_product)
    wood_univ.reload
    univ_size_after  = wood_univ.products.size
    cust1 = txt2cust(:cust1)
    cust2 = txt2cust(:cust2)


    assert_equal(univ_size_before + 1, univ_size_after)
    assert_equal(3, cust1.orders.first.line_items.size)    
    assert_equal(4, cust2.orders.first.line_items.size)

    # Remove a product.  Should be removed from univ and cust2's order.
    #
    univ_size_before = wood_univ.products.size

    # puts "XXX 1 #{wood_univ.products.map(&:name).join(',')}"
    wood_univ.remove_product(Product.find_by_name("wood1"))
    wood_univ.reload
    # puts "XXX 2 #{wood_univ.products.map(&:name).join(',')}"
    univ_size_after  = wood_univ.products.size



    assert_equal(univ_size_before - 1, univ_size_after)
    assert_equal(3, cust1.orders.first.reload.line_items_uncancelled.size)    
    assert_equal(3, cust2.orders.first.reload.line_items_uncancelled.size)
    
  end
end

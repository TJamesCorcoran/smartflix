
require 'test_helper'

class PurchasingTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  def setup
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

  def test_index        
    input =  { 
      :cust1 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "video1", :instock => true },
                    {:name => "video2", :instock => true },
                    {:name => "video3", :instock => true, :cancelled => true } ]
        }
      },
      :cust2 => {
        :sf_order => { :orderDate => Date.today - 7,
          :server_name => "smartflix",
          :paid => true,
          :lis => [ {:name => "video2", :instock => true } ]
        }
      }
    }
    
    build_fake(input)

    #    cust  = txt2cust("cust1")
    #    copy  = txt2co(  "foo1")
    #    li    = txt2li(  "foo1")
    
    video1 = txt2tit( "video1")
    video2 = txt2tit( "video2")
    video3 = txt2tit( "video3")

    video1.copies.first.mark_as_scratched
    video2.copies.first.mark_as_scratched
    video3.copies.first.mark_as_scratched

    video2.create_copy

    # post condition:
    #    1) video1 - 1 li,  1 bad copy,   0 good copy - HIGH PRIORITY
    #    2) video2 - 2 lis, 1 bad copy,   1 good copy - MEDIUM PRIORITY
    #    3) video3 - 0 lis, 1 bad copy,   0 good copy - LOW PRIORITY

    polish_high = Purchasing.polishable_high
    polish_med  = Purchasing.polishable_med
    polish_low  = Purchasing.polishable_low

    # puts "copies"
    # Copy.find(:all).each { |c| puts "  * #{c.id} : #{c.product.name} // #{c.status}" }
    #
    #     puts "polish_high  = #{polish_high.inspect}"
    #     puts "polish_med   = #{polish_med.inspect}"
    #     puts "polish_low   = #{polish_low.inspect}"

    assert_equal(1, polish_high.size)
    assert_equal(video1.product_id, Copy[polish_high.first].product_id)

    assert_equal(1, polish_med.size)
    assert_equal(video2.product_id, Copy[polish_med.first].product_id)

    assert_equal(1, polish_low.size)
    assert_equal(video3.product_id, Copy[polish_low.first].product_id)



  end

end

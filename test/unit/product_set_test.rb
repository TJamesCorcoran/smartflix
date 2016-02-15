require 'test_helper'

class ProductSetTest < ActiveSupport::TestCase
  fixtures :product_bundles

  def test_bundles

    ps = ProductSet.find(1)
    assert_equal(1, ps.product_set_id)
    assert_equal('Product set 1', ps.name)
    assert_equal(0.80, ps.discount_multiplier)
    assert !ps.backordered? 

    
    # back ordered-ness of sets and their elements:
    
    pds = ProductSetMembership.find(:all, :conditions => {:product_set_id => 1})
    pds.each do |pdi|
      assert !Product.find(pdi.product_id).backordered?
    end

    ps = ProductSet.find(2)
    assert_equal(ps.name, "Product set 2 (back ordered)")

    assert ps.backordered?
    
    pds = ProductSetMembership.find(:all, :conditions => {:product_set_id => 2}) 
    pds.each do |pdi|
      assert Product.find(pdi.product_id).backordered?
    end
  end
end

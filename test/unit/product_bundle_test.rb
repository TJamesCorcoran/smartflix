require 'test_helper'

class ProductBundleTest < ActiveSupport::TestCase
  fixtures :product_bundles

  def test_bundles

    pb = ProductBundle.find(1)
    assert_equal(pb.product_bundle_id, 1)
    assert_equal(pb.name, "bundle1")
    assert_equal(pb.description, "Some videos here")
    assert_equal(pb.discount_multiplier, 0.80)
    
    assert_equal(pb.backordered?, false)

    pb = ProductBundle.find(:all, :conditions => {:product_bundle_id => 3})[0]
    assert_equal(pb.description, "Bespoke to test the back-ordering logic")
    assert_equal(pb.name, "bundleBindle")

    assert_equal(pb.backordered?, true)

  end
end

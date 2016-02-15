require 'test_helper'

class ProductBundleMembershipTest < ActiveSupport::TestCase
  fixtures :product_bundle_memberships

  def test_bundle_membership

    pbm = ProductBundleMembership.find(1)
    assert_equal(pbm.product_bundle_membership_id, 1)
    assert_equal(pbm.product_bundle_id,1)
    assert_equal(pbm.product_id, 2)
  end
end

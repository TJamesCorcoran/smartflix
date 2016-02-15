require 'test_helper'

class ProductSetMembershipTest < ActiveSupport::TestCase
  fixtures :product_set_memberships
  
  def test_set_membership

    pbm = ProductSetMembership.find(1)
    assert_equal(pbm.product_set_membership_id, 1)
    assert_equal(pbm.product_set_id,1)
    assert_equal(pbm.product_id, 4)
    assert_equal(pbm.ordinal, 2)
    
  end
end

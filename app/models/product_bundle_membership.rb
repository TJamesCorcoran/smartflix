class ProductBundleMembership < ActiveRecord::Base
  self.primary_key ="product_bundle_membership_id"

  attr_protected # <-- blank means total access

  belongs_to :product
  belongs_to :product_bundle
end

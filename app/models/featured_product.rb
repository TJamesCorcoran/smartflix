class FeaturedProduct < ActiveRecord::Base
  self.primary_key = "featured_product_id"
  attr_protected # <-- blank means total access

  belongs_to :product
end

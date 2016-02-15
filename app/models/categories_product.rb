class CategoriesProduct < ActiveRecord::Base
  self.primary_key = "categories_product_id"
  attr_protected # <-- blank means total access

  belongs_to :product
  belongs_to :category
end

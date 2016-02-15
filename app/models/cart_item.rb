class CartItem < ActiveRecord::Base
  self.primary_key = "cart_item_id"

  attr_protected # <-- blank means total access


  belongs_to :cart
  belongs_to :product
  has_one :cart_item_discount_offer

  # Create a cart item for a particular product
  def CartItem.for_product(product)
    item = self.new
    item.product = product
    return item
  end

end

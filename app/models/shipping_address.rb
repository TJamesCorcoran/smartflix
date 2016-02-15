class ShippingAddress < Address
  attr_protected # <-- blank means total access

  has_one :customer
  def display_type
    'Shipping Address'
  end


end

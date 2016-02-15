class CouponUse < PriceModifier
  self.primary_key = "coupon_use_id"

  def display_string
    'Coupon Savings'
  end
end

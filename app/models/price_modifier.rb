class PriceModifier < ActiveRecord::Base
  self.primary_key ="price_modifier_id"

  attr_protected # <-- blank means total access

  belongs_to :order
  belongs_to :coupon
end

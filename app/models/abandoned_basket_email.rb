class AbandonedBasketEmail < ActiveRecord::Base
  self.primary_key = "abandoned_basket_email_id"

  attr_protected # <-- blank means total access

  belongs_to :customer
end

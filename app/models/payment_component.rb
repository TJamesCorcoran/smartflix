class PaymentComponent < ActiveRecord::Base
  self.primary_key = "payment_component_id"
  attr_protected # <-- blank means total access


  belongs_to :payment

end

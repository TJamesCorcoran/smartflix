class ChargebackDispute < ActiveRecord::Base
  self.primary_key = "chargeback_dispute_id"
  attr_protected # <-- blank means total access

  belongs_to :order
end

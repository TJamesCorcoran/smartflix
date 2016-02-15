class Purchaser < ActiveRecord::Base

  attr_protected # <-- blank means total access

  has_many :vendor_order_logs
  def full_name() name_first + " " + name_last end
end

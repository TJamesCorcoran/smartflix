class VendorOrderLog < ActiveRecord::Base
  self.primary_key ="vendor_order_log_id"

  attr_protected # <-- blank means total access

  belongs_to :product
  belongs_to :vendorMood, :foreign_key => 'title_id'
  belongs_to :purchaser

  has_one :vendor, :through => :product

  validates_numericality_of :quant
end

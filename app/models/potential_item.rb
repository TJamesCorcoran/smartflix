class PotentialItem < ActiveRecord::Base
  self.primary_key ="potential_item_id"

  attr_protected # <-- blank means total access

  belongs_to :potential_shipment
  belongs_to :line_item
  delegate :order, :to => :line_item  
end
  

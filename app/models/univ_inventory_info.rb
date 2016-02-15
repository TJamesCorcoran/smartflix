class UnivInventoryInfo < ActiveRecord::Base
  self.primary_key ="univ_inventory_info_id"

  attr_protected # <-- blank means total access


  belongs_to :university

end

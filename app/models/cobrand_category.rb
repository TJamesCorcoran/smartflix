class CobrandCategory < ActiveRecord::Base
  self.primary_key = "cobrand_category_id"
  attr_protected # <-- blank means total access

  belongs_to :cobrand
  belongs_to :category
end

class VendorMood < ActiveRecord::Base
  self.primary_key ="vendor_mood_id"

  attr_protected # <-- blank means total access

  has_many :vendors
  has_many :authors
  def name() moodText end
end

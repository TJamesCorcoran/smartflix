class Country < ActiveRecord::Base
  self.primary_key = "country_id"
  attr_protected # <-- blank means total access

end

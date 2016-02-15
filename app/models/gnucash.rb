class Gnucash < ActiveRecord::Base

  attr_protected # <-- blank means total access

  self.primary_key = "gnucash_id"
  self.table_name = "gnucash"
  
end

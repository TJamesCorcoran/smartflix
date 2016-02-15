class EmailPreference < ActiveRecord::Base
  self.primary_key = "email_preference_id"
  attr_protected # <-- blank means total access

  belongs_to :customer
  belongs_to :email_preference_type
end

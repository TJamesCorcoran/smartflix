class EmailPreferenceType < ActiveRecord::Base
  self.primary_key = "email_preference_type_id"
  attr_protected # <-- blank means total access

  self.primary_key = 'email_preference_type_id'
  has_many :email_preferences
  has_many :customers, :through => :email_preferences, :conditions => "email_preferences.send_email = 1"

end

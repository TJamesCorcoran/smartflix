class UspsPostageForm < ActiveRecord::Base
  self.primary_key ="usps_postage_form_id"

  attr_protected # <-- blank means total access

  belongs_to :person
end

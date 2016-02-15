class ContestPingRequest < ActiveRecord::Base
  self.primary_key = "contest_ping_request_id"
  attr_protected # <-- blank means total access


  self.primary_key = "contest_ping_request_id"

  belongs_to :contest
  validates_format_of :email,
    :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
end

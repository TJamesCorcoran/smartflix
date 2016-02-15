class ContactMessage < ActiveRecord::Base
  self.primary_key = "contact_message_id"

  # We use mass assignment, so limit inputs for security
  attr_accessible :name, :email, :message

  belongs_to :customer

  validates_presence_of :name
  validates_length_of :name, :minimum => 3

  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  validates_presence_of :message
  validates_length_of :message, :minimum => 10

end

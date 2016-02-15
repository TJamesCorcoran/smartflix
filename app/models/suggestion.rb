class Suggestion < ActiveRecord::Base
  self.primary_key ="suggestion_id"

  attr_protected # <-- blank means total access


  # We use mass assignment, so limit inputs for security
  attr_accessible :name, :email, :title, :where_to_buy

  belongs_to :customer

  validates_presence_of :name
  validates_length_of :name, :minimum => 3

  validates_presence_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  validates_presence_of :title
  validates_length_of :title, :minimum => 3

end

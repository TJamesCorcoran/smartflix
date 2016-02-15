# newsletters are sent to a group of people, 
# e.g. "all", "DC fans", "woodworkers", etc.
#
# this class represents the class of customers
#
class NewsletterCategory < ActiveRecord::Base
  attr_protected # <-- blank means total access

  has_many :newsletters
  
  def customers
    eval(code)
  end
  
end

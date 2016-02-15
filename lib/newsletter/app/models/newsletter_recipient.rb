# when a newsletter is ACTUALLY sent, we record each and every person we mailed it to
#
class NewsletterRecipient < ActiveRecord::Base

  attr_protected # <-- blank means total access
  
  belongs_to :newsletter
  belongs_to :customer
  
end

# each newsletter is composed of multiple sections: header, intro, product 1, etc.
#
class NewsletterSection < ActiveRecord::Base
  attr_protected # <-- blank means total access

  belongs_to :newsletter
  has_many :fields, :class_name => 'NewsletterSectionField'
end

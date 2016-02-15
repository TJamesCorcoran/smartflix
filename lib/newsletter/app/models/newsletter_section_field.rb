# each newsletter is composed of multiple sections: header, intro, product 1, etc.
# some sections take arguments (or "fields")
# e.g. product block 1 (which talks about Graphic Novel "V for Vendetta") has a field
# for the ID of the GN
#
class NewsletterSectionField < ActiveRecord::Base
  attr_protected # <-- blank means total access

  belongs_to :section, :class_name => 'NewsletterSection'
end

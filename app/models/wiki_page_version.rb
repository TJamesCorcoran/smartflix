class WikiPageVersion  < ActiveRecord::Base
  attr_protected # <-- blank means total access

  belongs_to :editor, :foreign_key => :customer_id, :class_name => "Customer"
  self.primary_key ="wiki_page_version_id"

  belongs_to :wiki_page

end

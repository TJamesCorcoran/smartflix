class DisplayCategory < ActiveRecord::Base
  attr_protected # <-- blank means total access

  self.primary_key = 'display_category_id'
  has_many :categories

  def self.all_ordered
    find(:all, :order => "`order`")
  end

end

class PromotionPage < ActiveRecord::Base
  self.primary_key ="promotion_page_id"

  attr_protected # <-- blank means total access

  belongs_to :promotion
  
  def last_page?
    promotion.ordered_pages.last.id == id
  end
  def first_page?
    promotion.ordered_pages.first.id == id
  end
end

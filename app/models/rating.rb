class Rating < ActiveRecord::Base
  self.primary_key ="rating_id"

  attr_protected # <-- blank means total access


  belongs_to :product
  belongs_to :customer

  validates_presence_of :rating
  validates_format_of :rating, :with => /^[1-5]$/, :message => 'must be selected'

  # People can just submit a rating with no review on the review page
  validates_length_of :review, :minimum => 40, :if => lambda { |r| r.review }

  def Rating.unapproved_reviews
    Rating.find(:all, :conditions => 'NOT ISNULL(review) AND ISNULL(approved)')
  end

  def summary(chars, with_stars_and_cust_name = true)
    ret = ""
    ret << "#{rating} stars! "  if with_stars_and_cust_name
    ret << review.truncate_at_word_for_charcount(chars) 
    ret << ((review.size < chars) ? "" : "..." ) 
    ret << " - #{customer.display_name}" if with_stars_and_cust_name && customer
    ret
  end

end

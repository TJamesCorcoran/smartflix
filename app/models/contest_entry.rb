class ContestEntry < ActiveRecord::Base
  self.primary_key = "contest_entry_id"
  attr_protected # <-- blank means total access


  MAX_PHOTOS = 3

  self.primary_key = "contest_entry_id"

  belongs_to :customer
  belongs_to :contest
  has_many   :contest_votes
  has_many   :contest_entry_photos

  validates_presence_of :customer_id, :contest_id, :title

  def full_name
    "#{first_name} #{last_name}"
  end

  def is_voted_for_by(voter_email)
    self.contest_votes.find_all_by_voter_email(voter_email).length > 0
  end

  def entrant
    self.customer
  end

  def entrant=(customer)
    self.customer = customer
  end

  def votes
    self.contest_votes
  end

  def photos
    self.contest_photos
  end

  def vote_count
    self.contest_votes.count
  end

end

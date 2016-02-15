class ContestVote < ActiveRecord::Base
  self.primary_key = "contest_vote_id"
  attr_protected # <-- blank means total access

  MAX_PER_VOTER = 3
  belongs_to :contest_entry
  self.primary_key = "contest_vote_id"
  validates_format_of :voter_email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_presence_of :contest_entry_id, :voter_email

  def entry
    self.contest_entry
  end

  def entry=(entry)
    self.contest_entry = entry
  end

  def contest
    self.contest_entry.contest
  end
end

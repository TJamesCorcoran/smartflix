class ContestError < StandardError
end

class ContestEntryError < ContestError
end

class ContestVotingError < ContestError
end

class EntryAlreadyApplied < ContestEntryError
end

class CustomerAlreadyEntered < ContestEntryError
end

class NotInEntryPhase < ContestEntryError
end

class WrongContestForEntry < ContestVotingError
end

class NotInVotingPhase < ContestVotingError
end

class CustomerHasNoMoreVotes < ContestVotingError
end

class VoteAlreadyCast < ContestVotingError
end


class Contest < ActiveRecord::Base
  self.primary_key = "contest_id"

  attr_protected # <-- blank means total access


  ENTRY_PHASE   = 1
  VOTING_PHASE  = 2
  ARCHIVE_PHASE = 3

  validates_presence_of :title, :description

  has_many :contest_entries
  has_many :contest_ping_requests

#  neither of these seem to work for what we want to do...
#  possible rails bug; see: http://rails.lighthouseapp.com/projects/8994/tickets/323-has_many-through-belongs_to_association-bug
#  has_many :contest_votes, :through => :contest_entries
#  has_many :contest_votes, :finder_sql =>
#    'SELECT contest_votes.* FROM contest_votes  ' +
#    'INNER JOIN contest_entries ' +
#    'ON contest_votes.contest_entry_id = contest_entries.contest_entry_id ' +
#    'WHERE ((contest_entries.contest_id = #{contest_id}))'

  def contest_votes_by_voter_email(email)
    votes = []
    self.contest_entries.each do |e|
      e.contest_votes.each do |v|
        votes << v if v.voter_email == email
      end
    end
    votes
  end

  def has_been_voted_in_by(voter_email)
    self.contest_entries.each do |e|
      return true if e.votes.find_by_voter_email(voter_email)
    end
    return false
  end

  # finds all currently active (non-archived) contests
  def self.active
    find_all_by_phase([ENTRY_PHASE, VOTING_PHASE])
  end

  def self.most_recently_concluded
    find(:first, :order => "archive_date DESC")
  end

  def next_phase
    if self.phase != ARCHIVE_PHASE
      self.increment!(:phase)
      if self.phase == ARCHIVE_PHASE
        self.update_attributes(:archive_date => Time.now)
      end
    end
    # Let interested parties know (people entered, people "watching")
    contest_entries.each do |entry|
      ContestSfMailer.contest_ping(self, entry.customer.email)
    end
    contest_ping_requests.each do |request|
      ContestSfMailer.contest_ping(self, request.email)
    end
  end

  def add_entry(entry, customer)
    if !new_entry_errors(entry, customer)
      entry.customer = customer
      self.contest_entries << entry
    end
  end

  def has_been_entered_by(customer)
    !!self.contest_entries.find_by_customer_id(customer.id)
  end

  def cast_vote(entry, voter_email)
    if !new_vote_errors(entry, voter_email)
      ContestVote.create!(:voter_email      => voter_email,
                          :contest_entry_id => entry.id)
    end
  end

  def voter_votes_remaining(voter_email)
    ContestVote::MAX_PER_VOTER -
      self.contest_votes_by_voter_email(voter_email).length
  end

  def ranked_entries
    self.contest_entries.sort_by{ |e| e.vote_count }.reverse
  end

  def entries
    self.contest_entries
  end

  def photos
    self.contest_entry_photos
  end

  def phase_to_text
    case phase
    when ENTRY_PHASE then 'enter submissions'
    when VOTING_PHASE then 'vote on submissions'
    when ARCHIVE_PHASE then 'archived'
    else raise 'Unknown contest phase'
    end
  end

  protected

  def validate
    if !(ENTRY_PHASE..ARCHIVE_PHASE).to_a.include?(self.phase)
      errors.add(:phase, "invalid contest phase: #{self.phase}")
    end
  end

  def new_entry_errors(entry, customer)
    if self.phase != ENTRY_PHASE
      raise NotInEntryPhase,
      "Contest #{self.id} is not in entry phase, cannot accept new entries."
      true
    end
    if entry.contest_id != nil
      raise EntryAlreadyApplied,
      "ContestEntry #{entry.id} was already entered in a contest"
      true
    end
    if has_been_entered_by(customer)
      raise CustomerAlreadyEntered,
      "Customer #{customer.id} has already entered contest #{self.id}"
      true
    end
    false
  end

  def new_vote_errors(entry, voter)
    if entry.contest != self
      raise WrongContestForEntry,
      "ContestEntry #{entry.id} does not belong to contest #{self.id}"
      true
    end
    if self.phase != VOTING_PHASE
      raise NotInVotingPhase,
      "Contest #{self.id} is not in voting phase, cannot accept votes."
      true
    end
    if entry.contest_votes.find_by_voter_email(voter)
      raise VoteAlreadyCast,
      "#{voter} has already voted for entry #{entry.id}"
      true
    end
    if self.voter_votes_remaining(voter) < 1
      raise CustomerHasNoMoreVotes,
      "#{ContestVote::MAX_PER_VOTER} votes allowed per voter per contest."
      true
    end
    false
  end
end

require 'test_helper'

class ContestEntryTest < ActiveSupport::TestCase
  fixtures :contests, :customers, :contest_entries, :contest_votes

  def test_is_voted_for_by
    vote = contest_votes(:one_votes_for_two_in_one)
    entry = vote.contest_entry
    voter = vote.voter_email
    assert(entry.is_voted_for_by(voter))
  end

end

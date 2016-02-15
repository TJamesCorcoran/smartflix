require 'test_helper'

class RatingTest < ActiveSupport::TestCase
  fixtures :products

  def test_summary

    rr = Rating.create(:product => products(:product1),
                       :customer => nil,
                       :rating => 5,
                       :review =>"Wonderful! I learned a lot.",
                       :approved => true)
    # should not blow up even on nil customer
    assert_equal("5 stars! Wonderful! I learned...", rr.summary(20))
  end
end

class AddTweetAbTests < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:tweet_in_nav,    9, 0.0, [:false, :true], true)
    AbTester.create_test(:tweet_in_video,  9, 0.0, [:false, :true], true)
  end

  def self.down
    AbTest.find_by_name("TweetInNav").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("TweetInVideo").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

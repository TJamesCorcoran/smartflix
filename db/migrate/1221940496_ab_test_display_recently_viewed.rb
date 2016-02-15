class AbTestDisplayRecentlyViewed < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:show_recently_viewed_box,  8, 0.0, [:false, :true])
  end

  def self.down
    AbTest.find_by_name("ShowRecentlyViewedBox").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

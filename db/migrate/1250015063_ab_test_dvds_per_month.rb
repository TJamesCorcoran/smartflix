class AbTestDvdsPerMonth < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:univ_funnel_permonth_choices,  8, 0.0, [:a123, :b234, :c1236, :d2368, :e368], :active => false)
  end

  def self.down
    AbTest.find_by_name("UnivFunnelPermonthChoices").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

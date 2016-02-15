class AbTestNewFunnel < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:funnel_type,  9, 0.0, [:old, :new_with_indivs, :new_univs_only], true)
  end

  def self.down
    AbTest.find_by_name("FunnelType").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

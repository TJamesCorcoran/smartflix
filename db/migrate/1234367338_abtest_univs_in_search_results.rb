class AbtestUnivsInSearchResults < ActiveRecord::Migration
  def self.up
    AbTester.create_test("univs_in_search_results", 2, 0.0, [:false, :true])
  end

  def self.down
    AbTester.destroy_test("univs_in_search_results")
  end
end

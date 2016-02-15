class AbtestUnivsOnFrontpage < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:frontpage_univ_stubs, 6, 0.0, [:false, :true])
  end

  def self.down
    AbTest.destroy_test(:frontpage_univ_stubs)
  end
end

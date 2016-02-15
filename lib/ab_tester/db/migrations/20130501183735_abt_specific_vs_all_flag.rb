class AbtSpecificVsAllFlag < ActiveRecord::Migration
  def up
    add_column     :ab_tests, :convert_by_default, :boolean, :default => true, :null => false, :after => :base_result
    add_column     :ab_tests, :convert_location, :string, :null => false, :after => :convert_by_default
  end

  def down
    remove_column     :ab_tests, :convert_by_default
    remove_column     :ab_tests, :convert_location
  end
end

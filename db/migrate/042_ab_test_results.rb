class AbTestResults < ActiveRecord::Migration
  def self.up
    create_table(:ab_test_results, :primary_key => 'ab_test_result_id') do |t|
      t.column :ab_test_visitor_id, :integer, :null => false
      t.column :ab_test_id, :integer, :null => false
      t.column :ab_test_option_id, :integer, :null => false
      t.column :value, :string, :null => false
      t.column :updated_at, :datetime, :null => false
    end
    add_index :ab_test_results, :ab_test_visitor_id
    add_index :ab_test_results, :ab_test_id
  end

  def self.down
    drop_table :ab_test_results
  end
end

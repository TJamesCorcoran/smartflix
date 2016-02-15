class AbTests < ActiveRecord::Migration
  def self.up
    create_table(:ab_tests, :primary_key => 'ab_test_id') do |t|
      t.column :active, :boolean, :null => false, :default => true
      t.column :name, :string, :null => false
      t.column :flight, :integer, :null => false
      t.column :spacing, :integer, :null => false
      t.column :result_type, :string, :null => false
      t.column :base_result, :string, :null => false
    end
    add_index :ab_tests, :name, :unique => true
  end

  def self.down
    drop_table :ab_tests
  end
end

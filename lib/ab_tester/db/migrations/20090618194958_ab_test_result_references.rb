class AbTestResultReferences < ActiveRecord::Migration
  def self.up
    create_table :ab_test_result_references do |t|
      t.column :ab_test_result_id, :integer, :null => false
      t.column :reference_id, :integer, :null => false
      t.column :reference_type, :string, :null => false
      t.timestamps
    end
    add_index :ab_test_result_references, :reference_id
    add_column :ab_test_results, :has_references, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :ab_test_results, :has_references
    drop_table :ab_test_result_references
  end
end

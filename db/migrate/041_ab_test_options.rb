class AbTestOptions < ActiveRecord::Migration
  def self.up
    create_table(:ab_test_options, :primary_key => 'ab_test_option_id') do |t|
      t.column :ab_test_id, :integer, :null => false
      t.column :name, :string, :null => false
      t.column :ordinal, :integer, :null => false
    end
    add_index :ab_test_options, :ab_test_id
  end

  def self.down
    drop_table :ab_test_options
  end
end

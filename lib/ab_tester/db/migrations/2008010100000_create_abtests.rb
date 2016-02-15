class CreateAbtests < ActiveRecord::Migration
  def self.up
    create_table(:ab_tests) do |t|
      t.column :active, :boolean, :null => false
      t.column :name, :string, :null => false
      t.column :ordinal, :integer, :null => false
      t.column :spacing, :integer, :null => false
      t.column :result_type, :string, :null => false
      t.column :base_result, :string, :null => false

      t.column :created_at,  :datetime, :null => false
      t.column :updated_at,  :datetime, :null => false
    end
    add_index :ab_tests, :name

    create_table(:ab_test_options) do |t|
      t.column :ab_test_id, :integer, :null => false
      t.column :name, :string, :null => false
      t.column :ordinal, :integer, :null => false
      t.column :created_at,  :datetime, :null => false
      t.column :updated_at,  :datetime, :null => false

    end
    add_index :ab_test_options, :ab_test_id

    create_table(:ab_test_results) do |t|
      t.column :ab_test_visitor_id, :integer, :null => false
      t.column :ab_test_id, :integer, :null => false
      t.column :ab_test_option_id, :integer, :null => false
      t.column :value, :string, :null => false

      t.column :order_id, :integer, :null => true
      t.column :created_at,  :datetime, :null => false
      t.column :updated_at,  :datetime, :null => false

    end
    add_index :ab_test_results, :order_id
    add_index :ab_test_results, :ab_test_visitor_id
    add_index :ab_test_results, :ab_test_id
    add_index :ab_test_results, :ab_test_option_id

    create_table(:ab_test_visitors) do |t|
      t.column :customer_id, :integer, :null => true
    end
    add_index :ab_test_visitors, :customer_id

  end

  def self.down
    drop_table :ab_tests
    drop_table :ab_test_options
    drop_table :ab_test_results
    drop_table :ab_test_visitors
  end
end

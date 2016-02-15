class AddTimestampsToAbtests < ActiveRecord::Migration
  def self.up
    add_column(:ab_tests, :created_at, :datetime, :null => false)
    add_column(:ab_tests, :updated_at, :datetime, :null => false)
    
    add_column(:ab_test_options, :created_at, :datetime, :null => false)
    add_column(:ab_test_options, :updated_at, :datetime, :null => false)
    
    add_column(:ab_test_results, :order_id,   :integer, :null => true)
    add_column(:ab_test_results, :created_at, :datetime, :null => false)
    add_index :ab_test_results, :order_id
    
    add_column(:ab_test_visitors, :customer_id, :integer, :null => true)
    add_column(:ab_test_visitors, :created_at, :datetime, :null => false)
    add_column(:ab_test_visitors, :updated_at, :datetime, :null => false)
    add_index :ab_test_visitors, :customer_id
    
  end

  def self.down
    remove_column(:ab_tests, :created_at)
    remove_column(:ab_tests, :updated_at)
   
    remove_column(:ab_test_options, :created_at)
    remove_column(:ab_test_options, :updated_at)
    
    remove_column(:ab_test_results, :order_id)
    remove_column(:ab_test_results, :created_at)
    
    remove_column(:ab_test_visitors, :customer_id)
    remove_column(:ab_test_visitors, :created_at)
    remove_column(:ab_test_visitors, :updated_at)

  end
end

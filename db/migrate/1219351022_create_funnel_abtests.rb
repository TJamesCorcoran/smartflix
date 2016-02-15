class CreateFunnelAbtests < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:funnel_frontpage, 6, 0.0, [:true, :false])
    AbTester.create_test(:funnel_catpage,   6, 0.0, [:true, :false])
    AbTester.create_test(:funnel_videopage, 6, 0.0, [:true, :false])
    AbTester.create_test(:funnel_discounts, 6, 0.0, [:zero, :two, :five])
    add_column :customers, :arrived_via_email_capture, :boolean,  :null => false, :default => false
    add_column :customers, :created_at,                :datetime, :null => false
    add_column :customers, :date_full_customer,        :date,     :null => true
    
    create_table(:payment_components, :primary_key => 'payment_component_id') do |t|
      t.column :payment_id,     :integer, :null => false
      t.column :amount,         :decimal, :null => false, :precision => 9, :scale => 2, :default => '0.00'
      t.column :payment_method, :string,  :null => false
      t.timestamps
    end
  end

  def self.down
    AbTest.find_by_name("FunnelFrontpage").destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("FunnelCatpage"  ).destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("FunnelVideopage").destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("FunnelDiscounts").destroy_self_and_children([:ab_test_options, :ab_test_results])
    remove_column :customers, :arrived_via_email_capture
    remove_column :customers, :created_at
    remove_column :customers, :date_full_customer
    drop_table :payment_components
  end
end

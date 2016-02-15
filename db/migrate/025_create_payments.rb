class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table(:payments, :primary_key => 'payment_id') do |t|
      t.column :order_id, :integer, :null => true
      t.column :customer_id, :integer, :null => false
      t.column :payment_method, :string, :null => false
      t.column :credit_card_id, :integer, :null => true, :default => nil
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :amount_as_new_revenue, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :cart_hash, :string, :null => true
      t.column :complete, :boolean, :null => false, :default => false
      t.column :successful, :boolean, :null => false, :default => false
      t.column :updated_at, :datetime, :null => false
    end
    add_index :payments, :order_id
    add_index :payments, :customer_id
  end

  def self.down
    drop_table :payments
  end
end

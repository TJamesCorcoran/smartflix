class CreateAffiliateTransactions < ActiveRecord::Migration
  def self.up
    create_table(:affiliate_transactions, :primary_key => 'affiliate_transaction_id') do |t|
      t.column :transaction_type, :string, :limit => 1, :null => false
      t.column :affiliate_customer_id, :integer, :null => false
      t.column :referred_customer_id, :integer, :null => true
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :date, :date, :null => false
    end
    add_index :affiliate_transactions, :affiliate_customer_id
  end

  def self.down
    drop_table :affiliate_transactions
  end
end

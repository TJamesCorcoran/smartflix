class CreateAccountCreditTransactions < ActiveRecord::Migration
  def self.up
    create_table(:account_credit_transactions, :primary_key => 'account_credit_transaction_id') do |t|
      t.column :account_credit_id, :integer, :null => false
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :gift_certificate_id, :integer, :null => true
      t.column :payment_id, :integer, :null => true
      t.column :transaction_type, :string, :null => false
    end
  end

  def self.down
    drop_table :account_credit_transactions
  end
end

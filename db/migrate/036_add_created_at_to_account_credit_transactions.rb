class AddCreatedAtToAccountCreditTransactions < ActiveRecord::Migration
  def self.up
    add_column(:account_credit_transactions, :created_at, :datetime, :null => false)
  end

  def self.down
    remove_column(:account_credit_transactions, :created_at)
  end
end

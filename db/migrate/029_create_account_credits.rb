class CreateAccountCredits < ActiveRecord::Migration
  def self.up
    create_table(:account_credits, :primary_key => 'account_credit_id') do |t|
      t.column :customer_id, :integer, :null => false
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
    end
    add_index :account_credits, :customer_id
  end

  def self.down
    drop_table :account_credits
  end
end

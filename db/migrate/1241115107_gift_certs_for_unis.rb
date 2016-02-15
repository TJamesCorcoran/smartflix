class GiftCertsForUnis < ActiveRecord::Migration
  def self.up
    add_column    :gift_certificates, :univ_months, :integer, :null=>true
    change_column :gift_certificates, :amount, :decimal, :precision => 9, :scale => 2, :default => nil, :null => true

    add_column    :account_credits,   :univ_months, :integer, :default => 0, :null => false

    add_column    :account_credit_transactions,   :univ_months, :integer,  :default => 0,  :null => true
    change_column :account_credit_transactions, :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => true
  end

  def self.down
    remove_column :gift_certificates, :univ_months
    change_column :gift_certificates, :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false


    remove_column :account_credits,   :univ_months

    remove_column :account_credit_transactions,   :univ_months
    change_column :gift_certificates, :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
  end
end

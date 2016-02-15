class AddTimestampsToCc < ActiveRecord::Migration
  def self.up
    add_column(:credit_cards, :created_at, :datetime, :null => false)
    add_column(:credit_cards, :updated_at, :datetime, :null => false)
    execute "update credit_cards set created_at = '2001-01-01 01:01:01', updated_at = '2001-01-01 01:01:01'"
  end

  def self.down
    remove_column(:credit_cards, :created_at)
    remove_column(:credit_cards, :updated_at)
  end
end

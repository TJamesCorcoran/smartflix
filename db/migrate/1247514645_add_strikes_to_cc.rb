class AddStrikesToCc < ActiveRecord::Migration
  def self.up
    add_column :credit_cards, :extra_attempts, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :credit_cards, :extra_attempts
  end
end

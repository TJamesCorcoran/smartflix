class AddDisabledToCreditCards < ActiveRecord::Migration
  def self.up
    add_column :credit_cards, :disabled, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :credit_cards, :disabled
  end
end

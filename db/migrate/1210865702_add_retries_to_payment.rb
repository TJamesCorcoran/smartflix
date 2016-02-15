class AddRetriesToPayment < ActiveRecord::Migration
  def self.up
    add_column :payments, :retry_attempts, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :payments, :retry_attempts
  end
end

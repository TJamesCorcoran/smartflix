class AddShipRateToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :ship_rate, :integer, :null => false, :default => 4
  end

  def self.down
    remove_column :customers, :ship_rate
  end
end

class AddServerNameToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :server_name, :string, :null => true, :default => nil
  end

  def self.down
    remove_column :orders, :server_name
  end
end

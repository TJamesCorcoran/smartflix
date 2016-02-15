class AddTimestampsToPotentialShipments < ActiveRecord::Migration
  def self.up
    add_column    :potential_shipments, :created_at,  :datetime, :null => false
    add_column    :potential_shipments, :updated_at,  :datetime, :null => false
    add_column    :potential_items, :created_at,  :datetime, :null => false
    add_column    :potential_items, :updated_at,  :datetime, :null => false
  end

  def self.down
    remove_column    :potential_shipments, :created_at
    remove_column    :potential_shipments, :updated_at
    remove_column    :potential_items, :created_at
    remove_column    :potential_items, :updated_at
  end
end

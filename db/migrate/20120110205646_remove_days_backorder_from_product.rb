class RemoveDaysBackorderFromProduct < ActiveRecord::Migration
  def self.up
    remove_column :products,  :days_backorder
  end

  def self.down
    add_column :products,   :days_backorder, :default => 0, :null => false
  end
end

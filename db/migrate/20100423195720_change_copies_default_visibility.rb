class ChangeCopiesDefaultVisibility < ActiveRecord::Migration
  def self.up
    change_column :copies, :visibleToShipperP, :boolean, :default => true
  end

  def self.down
    change_column :copies, :visibleToShipperP, :boolean, :default => false
  end
end

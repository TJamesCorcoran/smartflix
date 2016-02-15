class SetDefaultsForVendor < ActiveRecord::Migration
  def self.up
    change_column :vendors, :outOfBusinessP, :boolean, :default => false
  end

  def self.down
    change_column :vendors, :outOfBusinessP,  :boolean
  end
end

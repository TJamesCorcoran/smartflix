class AddDefaultInprintToProducts < ActiveRecord::Migration
  def self.up
    change_column :products, :in_print, :boolean, :default => true
  end

  def self.down
    change_column :products, :in_print, :boolean
  end
end

class AddDefaultToInventoryOrdered < ActiveRecord::Migration
  def self.up
    change_column_default(:inventory_ordereds, :quant_dvd, 0)
  end

  def self.down
    change_column_default(:inventory_ordereds, :quant_dvd, nil)

  end
end

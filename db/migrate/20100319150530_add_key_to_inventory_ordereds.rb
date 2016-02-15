class AddKeyToInventoryOrdereds < ActiveRecord::Migration
  def self.up
    drop_table :inventory_ordereds
    create_table :inventory_ordereds do |t|
      t.column :product_id, :integer, :null => false
      t.column :quant_dvd,  :integer, :null => false
    end
    add_index    :inventory_ordereds, :product_id

    remove_column :tobuys, :updated_at
    add_column    :tobuys, :created_at,  :datetime, :null => false
    add_column    :tobuys, :updated_at,  :datetime, :null => false

    Tobuy.destroy_all
  end

  def self.down
    drop_table :inventory_ordereds
    create_table :inventory_ordereds, :primary_key => :product_id do |t|
      t.column :quant_dvd,  :integer, :null => false
    end

    remove_column :tobuys, :created_at
  end
end

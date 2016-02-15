class AddOriginToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :origin_code, :string
  end

  def self.down
    remove_column :orders, :origin_code
  end
end

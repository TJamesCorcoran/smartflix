class AddIndexToOrdersOriginCode < ActiveRecord::Migration
  def self.up
    add_index    :orders, :origin_code
  end

  def self.down
    remove_index :orders, :origin_code
  end
end

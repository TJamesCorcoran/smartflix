class AddIndexToOriginsTable < ActiveRecord::Migration
  def self.up
    add_index :origins, :customer_id
  end

  def self.down
    remove_index :origins, :customer_id
  end
end

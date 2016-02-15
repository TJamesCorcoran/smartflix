class CreateCarts < ActiveRecord::Migration
  def self.up
    create_table(:carts, :primary_key => :cart_id) do |t|
      t.column :customer_id, :integer
    end
    add_index :carts, :customer_id
  end

  def self.down
    drop_table :carts
  end
end

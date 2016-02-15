class CreateCartItems < ActiveRecord::Migration
  def self.up
    create_table(:cart_items, :primary_key => 'cart_item_id') do |t|
      t.column :cart_id, :integer, :null => false
      t.column :product_id, :integer, :null => false
      t.column :saved_for_later, :bool, :null => false, :default => false
      t.column :created_at, :datetime, :null => false
    end
    add_index :cart_items, :cart_id
  end

  def self.down
    drop_table :cart_items
  end
end

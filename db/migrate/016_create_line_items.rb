class CreateLineItems < ActiveRecord::Migration
  def self.up
    create_table(:line_items, :primary_key => 'line_item_id') do |t|
      t.column :order_id, :integer, :null => false
      t.column :product_id, :integer, :null => false
      t.column :price, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
    end
    add_index :line_items, :order_id
  end

  def self.down
    drop_table :line_items
  end
end

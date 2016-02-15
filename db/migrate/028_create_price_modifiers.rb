class CreatePriceModifiers < ActiveRecord::Migration
  def self.up
    create_table(:price_modifiers, :primary_key => 'price_modifier_id') do |t|
      t.column :order_id, :integer, :null => true
      t.column :type, :string, :null => false
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :coupon_id, :integer, :null => true
    end
    add_index :price_modifiers, :order_id
    add_index :price_modifiers, :coupon_id
  end

  def self.down
    drop_table :price_modifiers
  end
end

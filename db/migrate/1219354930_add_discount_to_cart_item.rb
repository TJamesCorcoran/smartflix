class AddDiscountToCartItem < ActiveRecord::Migration
  def self.up

    add_column :cart_items, :discount, :decimal

  end

  def self.down

    remove_column :cart_items, :discount

  end
end

class CreateCategoriesProducts < ActiveRecord::Migration
  def self.up
    create_table(:categories_products, :id => false) do |t|
      t.column :product_id, :integer, :null => false
      t.column :category_id, :integer, :null => false
    end
    add_index :categories_products, :product_id
    add_index :categories_products, :category_id
  end

  def self.down
    drop_table :categories_products
  end
end

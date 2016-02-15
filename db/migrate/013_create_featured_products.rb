class CreateFeaturedProducts < ActiveRecord::Migration
  def self.up
    create_table(:featured_products, :primary_key => 'featured_product_id') do |t|
      t.column :product_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :featured_products
  end
end

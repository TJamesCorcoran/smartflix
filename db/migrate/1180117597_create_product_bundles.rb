class CreateProductBundles < ActiveRecord::Migration
  def self.up
    create_table( :product_bundles, :primary_key => 'product_bundle_id' ) do |t|
      t.column :name, :string
      t.column :discount_multiplier, :float, :precision => 1, :scale => 2
    end
  end

  def self.down
    drop_table :product_bundles
  end
end

class AddDescriptionToBundles < ActiveRecord::Migration
  def self.up
    add_column :product_bundles, :description, :text
  end

  def self.down
    remove_column :product_bundles, :description
  end
end

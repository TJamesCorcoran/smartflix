class CreateProductBundleMemberships < ActiveRecord::Migration
  def self.up
    create_table( :product_bundle_memberships, :primary_key => 'product_bundle_membership_id' ) do |t|
      t.column :product_id, :integer
      t.column :product_bundle_id, :integer
    end
    add_index :product_bundle_memberships, :product_id
    add_index :product_bundle_memberships, :product_bundle_id
  end

  def self.down
    drop_table :product_bundle_memberships
  end
end

class AddOrdinalToProductBundleMemberships < ActiveRecord::Migration
  def self.up
    add_column :product_bundle_memberships, :ordinal, :integer
  end

  def self.down
    remove_column :product_bundle_memberships, :ordinal
  end
end

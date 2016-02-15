class CreateProductSetMemberships < ActiveRecord::Migration
  def self.up
    create_table(:product_set_memberships, :primary_key => 'product_set_membership_id') do |t|
      t.column :product_id, :integer, :null => false
      t.column :product_set_id, :integer, :null => false
      t.column :ordinal, :integer, :null => false
    end
    add_index :product_set_memberships, :product_id
    add_index :product_set_memberships, :product_set_id
  end

  def self.down
    drop_table :product_set_memberships
  end
end

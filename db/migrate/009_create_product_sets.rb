class CreateProductSets < ActiveRecord::Migration
  def self.up
    create_table(:product_sets, :primary_key => 'product_set_id')  do |t|
      t.column :name, :string, :null => false
      t.column :describe_each_title, :bool, :null => false
      t.column :discount_multiplier, :decimal, :precision => 4, :scale => 2, :default => '0.00', :null => false
    end
  end

  def self.down
    drop_table :product_sets
  end
end

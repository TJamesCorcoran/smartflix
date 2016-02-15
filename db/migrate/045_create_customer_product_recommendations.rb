class CreateCustomerProductRecommendations < ActiveRecord::Migration
  def self.up
    create_table(:customer_product_recommendations, :primary_key => :customer_product_recommendation_id) do |t|
      t.column :customer_id, :integer, :null => false
      t.column :product_id, :integer, :null => false
      t.column :ordinal, :integer, :null => false
    end
    add_index :customer_product_recommendations, :customer_id
  end

  def self.down
    drop_table :product_recommendations
  end
end

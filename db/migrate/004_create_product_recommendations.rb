class CreateProductRecommendations < ActiveRecord::Migration
  def self.up
    create_table(:product_recommendations, :primary_key => :product_recommendation_id) do |t|
      t.column :product_id,             :integer, :null => false
      t.column :recommended_product_id, :integer, :null => false
      t.column :ordinal,                :integer, :null => false
    end
    add_index :product_recommendations, :product_id
  end

  def self.down
    drop_table :product_recommendations
  end
end

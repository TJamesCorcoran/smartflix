class CreateCustomerCategoryRecommendations < ActiveRecord::Migration
  def self.up
    create_table(:customer_category_recommendations, :primary_key => :customer_category_recommendation_id) do |t|
      t.column :customer_id, :integer, :null => false
      t.column :category_id, :integer, :null => false
      t.column :ordinal, :integer, :null => false
    end
    add_index :customer_category_recommendations, :customer_id
  end

  def self.down
    drop_table :category_recommendations
  end
end

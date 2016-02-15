class AddTimestampsToRecos < ActiveRecord::Migration
  def self.up
    add_column     :customer_product_recommendations, :created_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"
    add_column     :customer_product_recommendations, :updated_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"

    add_column     :customer_category_recommendations, :created_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"
    add_column     :customer_category_recommendations, :updated_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"

    add_column     :product_recommendations, :created_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"
    add_column     :product_recommendations, :updated_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"


  end

  def self.down
    remove_column     :customer_product_recommendations, :created_at
    remove_column     :customer_product_recommendations, :updated_at

    remove_column     :customer_category_recommendations, :created_at
    remove_column     :customer_category_recommendations, :updated_at

    remove_column     :product_recommendations, :created_at
    remove_column     :product_recommendations, :updated_at


  end
end

class AddProductImageToUniv < ActiveRecord::Migration
  def self.up
    add_column     :universities, :featured_product_type, :string, :null => true
    add_column     :universities, :featured_product_id,   :integer, :null => true
  end

  def self.down
    remove_column     :universities, :featured_product_type
    remove_column     :universities, :featured_product_id
  end
end

class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table(:ratings, :primary_key => 'rating_id') do |t|
      t.column :product_id, :integer, :null => false
      t.column :customer_id, :integer, :null => false
      t.column :rating, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :review, :text, :default => nil
      t.column :approved, :bool, :null => false, :default => false
    end
    add_index :ratings, :product_id
    add_index :ratings, :customer_id
  end

  def self.down
    drop_table :ratings
  end
end

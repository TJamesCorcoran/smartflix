class CreateFavoriteProjectLinks < ActiveRecord::Migration
  def self.up
    create_table :favorite_project_links do |t|
      t.integer :customer_id, :null => false
      t.integer :project_id, :null => false
      t.timestamps
    end
    add_index :favorite_project_links, :customer_id
    add_index :favorite_project_links, :project_id
  end

  def self.down
    drop_table :favorite_project_links
  end
end

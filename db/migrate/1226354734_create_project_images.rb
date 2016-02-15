class CreateProjectImages < ActiveRecord::Migration
  def self.up
    create_table :project_images do |t|
      t.integer :project_update_id
      t.integer :parent_id
      t.string :content_type
      t.string :filename
      t.string :thumbnail
      t.integer :width
      t.integer :height
      t.integer :size
      t.text :caption
      t.text :caption_html
      t.timestamps
    end
    add_index :project_images, :project_update_id
    add_index :project_images, :parent_id
  end

  def self.down
    drop_table :project_images
  end
end

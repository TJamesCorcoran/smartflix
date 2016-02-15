class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :customer_id, :null => false
      t.integer :parent_id, :null => false
      t.string :parent_type, :null => false
      t.text :text, :null => false
      t.text :text_html, :null => false
      t.timestamps
    end
    add_index :comments, :customer_id
    add_index :comments, :parent_id
  end

  def self.down
    drop_table :comments
  end
end

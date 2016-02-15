class CreateProjectUpdates < ActiveRecord::Migration
  def self.up
    create_table :project_updates do |t|
      t.integer :project_id, :null => false
      t.text :text
      t.text :text_html
      t.timestamps
    end
    add_index :project_updates, :project_id
  end

  def self.down
    drop_table :project_updates
  end
end

class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.integer :customer_id, :null => false
      t.string :title, :null => false
      t.integer :status, :null => false
      t.integer :inspired_by_id
      t.timestamps
    end
    add_index :projects, :customer_id
    add_index :projects, :inspired_by_id
  end

  def self.down
    drop_table :projects
  end
end

class AddSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.column :session_id, :string
      t.column :data, :text
      t.column :updated_at, :datetime
    end
    
    add_index :sessions, :session_id
  end

  def self.down
    begin
      drop_table :sessions
    rescue
    end
  end
end

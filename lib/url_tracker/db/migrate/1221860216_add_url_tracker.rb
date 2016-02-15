class AddUrlTracker < ActiveRecord::Migration
  def self.up
    create_table(:url_tracks, :primary_key => 'url_track_id') do |t|
      t.column :session_id,      :string,  :null => false
      t.column :customer_id,     :integer
      t.column :path,            :string,  :null => false
      t.column :controller,      :string,  :null => false
      t.column :action,          :string,  :null => false
      t.column :action_id,       :string
      t.column :created_at,      :datetime, :null => false
    end
  end

  def self.down
    drop_table :url_tracks
  end
end

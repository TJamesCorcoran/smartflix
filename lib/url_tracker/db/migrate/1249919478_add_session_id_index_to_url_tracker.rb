class AddSessionIdIndexToUrlTracker < ActiveRecord::Migration
  def self.up
    rename_table :url_tracks, :url_tracks_old

    create_table(:url_tracks, :primary_key => 'url_track_id') do |t|
      t.column :session_id,      :string,  :null => false
      t.column :customer_id,     :integer
      t.column :path,            :string,  :null => false
      t.column :controller,      :string,  :null => false
      t.column :action,          :string,  :null => false
      t.column :action_id,       :string
      t.column :created_at,      :datetime, :null => false
    end

    add_index :url_tracks, :session_id
  end

  def self.down
#    drop_table :url_tracks
#    rename_table  :url_tracks_old, :url_tracks
  end
end

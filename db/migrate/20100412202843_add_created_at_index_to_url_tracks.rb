class AddCreatedAtIndexToUrlTracks < ActiveRecord::Migration
  def self.up
    add_index    :url_tracks, :created_at
  end

  def self.down
    remove_index    :url_tracks, :created_at
  end
end

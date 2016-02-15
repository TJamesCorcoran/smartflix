class AddContests < ActiveRecord::Migration
    def self.up
    create_table(:contests, :primary_key => 'contest_id') do |t|
      t.column :title,        :string,   :null => false
      t.column :description,  :text,     :null => false
      t.column :phase,        :integer,  :default => 1
      t.column :archive_date, :datetime, :null => true
    end
    create_table(:contest_entries, :primary_key => 'contest_entry_id') do |t|
      t.column :contest_id,  :integer, :null => false
      t.column :customer_id, :integer, :null => false
      t.column :first_name,  :string,  :null => false
      t.column :last_name,   :string,  :null => false
      t.column :title,       :string,  :null => false
      t.column :description, :text
    end
    create_table(:contest_votes, :primary_key => 'contest_vote_id') do |t|
      t.column :voter_email,      :string,  :null => false
      t.column :contest_entry_id, :integer, :null => false
    end
    create_table(:contest_entry_photos,
                 :primary_key => 'contest_entry_photo_id') do |t|
      t.column :parent_id,  :integer
      t.column :content_type, :string
      t.column :filename, :string
      t.column :thumbnail, :string
      t.column :size, :integer
      t.column :width, :integer
      t.column :height, :integer
      t.column :contest_entry_id, :string,  :null => false
      # t.column :position,         :integer
    end
    create_table(:contest_ping_requests,
                 :primary_key => 'contest_ping_request_id') do |t|
      t.column :contest_id, :integer, :null => false
      t.column :email,      :string,  :null => false
    end
  end

  def self.down
    drop_table :contests
    drop_table :contest_entries
    drop_table :contest_votes
    drop_table :contest_entry_photos
    drop_table :contest_ping_requests
  end
end

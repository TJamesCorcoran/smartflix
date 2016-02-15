class FixContestTables < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE contest_entries CHANGE COLUMN contest_id contest_id INTEGER NULL DEFAULT NULL")
  end

  def self.down
    execute("ALTER TABLE contest_entries CHANGE COLUMN contest_id contest_id INTEGER NOT NULL")
  end
end

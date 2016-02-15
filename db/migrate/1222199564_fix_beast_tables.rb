class FixBeastTables < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE customers CHANGE COLUMN posts_count posts_count INTEGER NOT NULL DEFAULT 0")
  end

  def self.down
    execute("ALTER TABLE customers CHANGE COLUMN posts_count posts_count INTEGER NULL DEFAULT NULL")
  end
end

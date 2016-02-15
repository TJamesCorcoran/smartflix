class UpdateApprovedForRatings < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE ratings CHANGE COLUMN approved approved TINYINT(1) NULL DEFAULT NULL"
    execute "UPDATE ratings SET approved = NULL WHERE approved = 0"
  end

  def self.down
    execute "UPDATE ratings SET approved = 0 WHERE ISNULL(approved)"
    execute "ALTER TABLE ratings CHANGE COLUMN approved approved TINYINT(1) NOT NULL DEFAULT 0"
  end
end

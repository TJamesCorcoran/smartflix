class AddUpdatedAtToOrigins < ActiveRecord::Migration
  def self.up
    add_column(:origins, :updated_at, :datetime, :null => false)
  end

  def self.down
    remove_column(:origins, :updated_at)
  end
end

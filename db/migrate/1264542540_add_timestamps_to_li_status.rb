class AddTimestampsToLiStatus < ActiveRecord::Migration
  def self.up
    add_column     :line_item_statuses, :updated_at,  :datetime, :null => false
  end

  def self.down
    remove_column     :line_item_statuses, :updated_at
  end
end

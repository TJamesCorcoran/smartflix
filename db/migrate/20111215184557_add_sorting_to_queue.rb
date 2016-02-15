class AddSortingToQueue < ActiveRecord::Migration
  def self.up
    add_column :line_items, :queue_position, :integer, :null => true
  end

  def self.down
    remove_column :line_items, :queue_position
  end
end

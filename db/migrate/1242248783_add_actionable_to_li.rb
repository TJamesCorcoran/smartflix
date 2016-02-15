class AddActionableToLi < ActiveRecord::Migration
  def self.up
    add_column :line_items, :actionable, :boolean, :default => true
  end

  def self.down
    remove_column :line_items, :actionable
  end
end

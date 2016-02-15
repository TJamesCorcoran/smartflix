class RenameLiUncancelField < ActiveRecord::Migration
  def self.up
    rename_column :line_items, :uncancelledP, :live
  end

  def self.down
    rename_column :line_items, :live, :uncancelledP
  end
end

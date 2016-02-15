class MakeLiIgnoreForUnivLimitsMandatory < ActiveRecord::Migration
  def self.up
    change_column :line_items, :ignore_for_univ_limits, :boolean, :default => false, :null => false
  end

  def self.down
    change_column :line_items, :ignore_for_univ_limits, :boolean, :default => null
  end
end

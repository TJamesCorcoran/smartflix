class FixOverdueGraceGranted < ActiveRecord::Migration
  def self.up
    change_column :line_item_auxes, :overdueGraceGranted, :integer
  end

  def self.down
    change_column :line_item_auxes, :overdueGraceGranted, :boolean
  end
end

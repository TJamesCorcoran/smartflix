class LiLawsuitFiledDate < ActiveRecord::Migration
  def self.up
    add_column :line_items, :lawsuit_filed, :datetime
    add_index  :line_items, :lawsuit_filed
  end

  def self.down
    remove_column :line_items, :lawsuit_filed, :datetime
  end
end

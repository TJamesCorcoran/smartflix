class AddLawsuitWarnings < ActiveRecord::Migration
  def self.up
    add_column :line_items, :lawsuit_snailmail, :datetime
    add_index  :line_items, :lawsuit_snailmail
  end

  def self.down
    remove_column :line_items, :lawsuit_snailmail, :datetime
  end
end

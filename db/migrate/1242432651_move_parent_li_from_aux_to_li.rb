class MoveParentLiFromAuxToLi < ActiveRecord::Migration
  def self.up
    remove_column :line_item_auxes, :parent_line_item_id
    add_column :line_items, :parent_line_item_id   , :integer
    add_index    :line_items, :parent_line_item_id
  end

  def self.down
    remove_column :line_item, :parent_line_item_id
    add_column :line_items_auxes, :parent_line_item_id   , :integer
    add_index    :line_item_auxes, :parent_line_item_id
  end
end

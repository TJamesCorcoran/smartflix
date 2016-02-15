class CreateLineItemProblems < ActiveRecord::Migration
  def self.up
    create_table(:line_item_problems, :primary_key => 'line_item_problem_id') do |t|
      t.column :line_item_id, :integer, :null => false
      t.column :line_item_problem_type_id, :integer, :null => false
      t.column :wrong_copy_id, :integer, :null => true
      t.column :details, :string, :null => true
      t.column :replacement_order_id, :integer, :null => true
    end
  end

  def self.down
    drop_table :line_item_problems
  end
end

class CreateLineItemProblemTypes < ActiveRecord::Migration
  def self.up
    create_table(:line_item_problem_types, :primary_key => 'line_item_problem_type_id') do |t|
      t.column :form_tag, :string, :null => false
    end
    LineItemProblemType.create(:form_tag => 'damaged_cracked')
    LineItemProblemType.create(:form_tag => 'damaged_not_readable')
    LineItemProblemType.create(:form_tag => 'damaged_skips')
    LineItemProblemType.create(:form_tag => 'damaged_freezes')
    LineItemProblemType.create(:form_tag => 'damaged_sound')
    LineItemProblemType.create(:form_tag => 'damaged_other')
    LineItemProblemType.create(:form_tag => 'wrong_dvd')
    LineItemProblemType.create(:form_tag => 'missing_handout')
    LineItemProblemType.create(:form_tag => 'late')
    LineItemProblemType.create(:form_tag => 'missing_return_label')
    LineItemProblemType.create(:form_tag => 'missing_box')
    LineItemProblemType.create(:form_tag => 'lost_by_customer')
  end

  def self.down
    drop_table :line_item_problem_types
  end
end

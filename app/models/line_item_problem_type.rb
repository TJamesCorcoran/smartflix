class LineItemProblemType < ActiveRecord::Base
  self.primary_key = "line_item_problem_type_id"
  attr_protected # <-- blank means total access

  has_many :line_item_problems
end

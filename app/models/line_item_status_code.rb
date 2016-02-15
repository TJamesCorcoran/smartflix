class LineItemStatusCode <  ActiveRecord::Base
  self.primary_key = "line_item_status_code_id"
  attr_protected # <-- blank means total access

  has_many :line_item_statuses
end

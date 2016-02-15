class LineItemStatus <  ActiveRecord::Base
  self.primary_key = "line_item_status_id"
  attr_protected # <-- blank means total access

  belongs_to :line_item
  belongs_to :line_item_status_code

  # Return the number of days this item is on backorder, in text format
  def wait_text
    case self.days_delay
    when -1, nil then 'after an unknown wait'
    when 0 then 'within one business day'
    when 1..9 then 'after a short wait'
    when 10..22 then 'after a moderate wait'
    when 23..34 then 'after a long wait'
    else 'after a very long wait'
    end
  end

end

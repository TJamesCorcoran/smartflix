class TimesheetItem  < ActiveRecord::Base


  attr_protected # <-- blank means total access

  self.primary_key = 'hr_timesheet_items_id'
  belongs_to :person, :foreign_key => :hr_person_id

public

  def hours_worked
    (self.end - self.begin) / 3600
  end

#  def validate
#    if ((self.begin <=> self.end ) <= 0)
#      errors.add(:begin, "after end" )
#    end
#  end

end

#require 'Date'

class Timesheet
  attr_reader :items

  public

  # Build a timesheet for a person and a week.
  #
  # Pass in a day.  We figure out the begin day (Monday) and end day (following Sun)  
  # First day of week may be specified either by a string or by a Date object
  #
  def initialize(person, date)
    @person = person
    if (date.class == "string".class )

      @key_day = Date.strptime(date)
    else
      @key_day = date
    end
    week_begin = @key_day - @key_day.wday + 1
    week_end   = @key_day - @key_day.wday + 7

    @items = {}
    tsi = TimesheetItem.find(:all, :conditions => [ "hr_person_id = ? AND TO_DAYS(date) >= TO_DAYS(?) AND TO_DAYS(date) <= TO_DAYS(?)", 
                                                     person, week_begin.strftime("%Y-%m-%d"), week_end.strftime("%Y-%m-%d") ])
#    raise week_begin.strftime + "..." + week_end.strftime

    @hours = 0
    tsi.each do | item |
      wday = item.date.wday() - 1
      if (wday == -1) then wday = 6 end
      if (@items [ wday ].nil?)
        @items[ wday ] = []
      end
      @items[ wday ].push(item)
      @hours = @hours + ((item.end - item.begin)  / 3600)
    end
  end

  def next_week()
    nw = Timesheet.new(@person, @key_day + 7)
    nw
  end

  def hours()
    @hours
  end

  def person()
    @person
  end

end

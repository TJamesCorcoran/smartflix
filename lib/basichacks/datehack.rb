require 'date'

# add a feature to ruby
# from
#    http://www.faeriemud.org/browser/trunk/lib/fm/utils.rb?format=txt
Class.class_eval do
  ### Alias a class method.
  def alias_class_method( newSym, oldSym )
    retval = nil
    eval %{
      class << self
        retval = alias_method :#{newSym}, :#{oldSym}
      end
    }
    return retval
  rescue Exception => err
    # Mangle exceptions to point someplace useful
    frames = err.backtrace
    frames.shift while frames.first =~ /#{__FILE__}/
      Kernel::raise err, err.message.gsub(/in `\w+'/, "in `alias_class_method'"), frames
  end


end

# Stolen from underdog_web/app/helpers/application_helper.rb
#
# Takes a date or time and formats it in a specific manner.  The
# purpose of this is to ensure that we display dates in a consistent
# manner throughout the site.
#
def display_date(input,style=:long)
  return 'UNKNOWN' if input.nil?

  if input.respond_to?(:to_date)
    input = input.to_date
  else
    raise ArgumentError, "#{input} is not like a Date."
  end

  case style
  when :tiny 
    input.strftime('%m/%d/%y')
  else
    input.to_formatted_s(style)
  end
end


# Instrument the Date class so that a test suite can force it to lie
# about the value of today.
#
# Usage:
#    Date.force_today ("2008-01-01") // force today to be Jan 1st
#       ...
#    Date.force_today (nil)          // restore
#
DateTime.class_eval do
  # backup Date.today() into Date.orig()
  alias_class_method(:orig, :now)

  def self.force_now(fd = nil)
    fd = DateTime.strptime(fd) if fd.class.to_s == "String"
    @force_now = fd
  end

  def self.now
    return @force_now.nil? ? orig : @force_now
  end
end

Time.class_eval do
  alias_class_method(:orig, :now)

  def self.force_now(fd = nil)
    if fd.class.to_s == "String"
      fd =Time.parse(fd) 
    elsif fd.class.to_s == "Date"
      fd = fd.to_time
    end
    @force_now = fd
  end

  def self.now
    return @force_now.nil? ? orig : @force_now
  end
end

Date.class_eval do
  # backup Date.today() into Date.orig()
  alias_class_method(:orig, :today)

  def Date.force_today(fd = nil)
    fd = Date.strptime(fd) if fd.class.to_s == "String"
    @force_date = fd
  end

  def Date.today
    return @force_date.nil? ? orig : @force_date
  end

  #  Given two dates, find the delta between then, e.g.
  #     "3 years, 2 months, 11 days, 3 hours, 0 minutes, 12 seconds"
  #
  #
  # verbose will mention years, months, etc. even if zero
  # non verbose will only mention the biggest non-zero unit, and everything after
  #
  # bugs:
  #   * defines a month as exactly 30 days.  Take today, and the same
  #     date a year ago, and the delta is 12 months and 5 days.
  #
  def Date.duration_str(start, finish, verbose = false, use_now_if_unfinished = false)

    start = start.to_datetime if start.is_a?(Time)
    finish = finish.to_datetime if finish.is_a?(Time)

    suffix = ""
    if use_now_if_unfinished && finish.nil?
      finish = DateTime.now 
      suffix = " ... and counting"
    end


    return "not started" unless start 
    return "not finished" unless finish

    delta_seconds = (finish.to_f - start.to_f).to_i
    delta_hours = delta_seconds / (60 * 60)

    years = delta_hours / 8760
    delta_hours = delta_hours % 8760

    months = delta_hours / 720
    delta_hours = delta_hours % 720

    days = delta_hours / 24
    hours = delta_hours % 24

    minutes = 0

    seconds = 0

    str = []

    [ [years, "years"], [months, "month"], [days, "day"], [hours, "hour"], [minutes, "minute"], [seconds, "second"] ].each do |pair|
      count, name = pair

      if verbose || count > 0 || str == "second"
        str << "#{count} #{name.pluralize_conditional(count)}"
        verbose = true
      end
    end
    str.join(", ") + suffix
  end
end

class Date

    class << self
      def wrap_day_fraction_to_time( day_frac )
        day_fraction_to_time( day_frac )
      end
   end

  # wday is day-of-week
  #    0 - Sun
  #    1 - Mon
  #    2 - Tues, etc.
  #
  # Given a date (say, a Thurs), you can ask for the last Monday before that date:
  #
  #      thursday_date.last_wday_on_or_before(3)
  def last_wday_on_or_before(wday)
    raise "illegal wday #{wday}" if wday < 0 || wday > 6
    delta = (self.wday - wday ) % 7
    self - delta
  end

  def first_wday_after(wday)
    last = last_wday_on_or_before(wday)
    last += 7 if last < self
    last
  end

  def self.from_month_and_year(first, second = nil)
    if second.nil? && first.is_a?(Array) && first.size == 2
      month = first[0]
      year = first[1]
    else
      month = first
      year = second
    end
    Date.parse("#{year}-#{sprintf('%02i', month)}-01").end_of_month()
  end

  def get_month_and_year
    [ self.month, self.year ]
  end
  
  def quarter
    case
      when self.month <= 3 then "1"
      when self.month <= 6 then "2"
      when self.month <= 9 then "3"
      when self.month <= 12 then "4"
    end
  end
  
  def is_first_month_of_quarter?
    [1,4,7,10].detect { |x| x == self.month } != false
  end


  #----------
  # month

  def first_of_month
    self - day + 1
  end

  def last_of_month
    (self >> 1) - day 
  end


  def is_first_day_of_month?
    self.day == 1
  end

  def first_day_of_month_in_next_n?(n)
    arr = []
    self.upto(self + n) { |x| arr << x}
    arr.detect { |dd| dd.is_first_day_of_month? }.to_bool
  end

  def is_first_week_of_month?
    self.day <= 7
  end


  #----------
  # quarter

  def is_first_day_of_quarter?
    self.is_first_month_of_quarter? && self.day == 1
  end

  def first_day_of_quarter_in_next_n?(n)
    arr = []
    self.upto(self + n) { |x| arr << x}
    arr.detect { |dd| dd.is_first_day_of_quarter? }.to_bool
  end

  def is_first_week_of_quarter?
    (self >= self.beginning_of_quarter) &&
      (self <= (self.beginning_of_quarter + 6 ))
  end

  #----------
  # year
  
  def is_first_day_of_year?
    self.month == 1 && self.day == 1
  end

  def is_first_week_of_year?
    self.month == 1 && (self.day <= 7 )
  end

  def is_first_month_of_year?
    self.month == 1
  end



  #----------
  # ???

  
  def beginning_of_quarter()    (self << ((self.month % 3) == 0 ? 2 : (self.month % 3) - 1 )).beginning_of_month  end
  def end_of_quarter()          (self >> ((3 - (self.month % 3)) % 3)).end_of_month  end
  def plus_quarter(arg)         self >> (3 * arg)  end


  
  # present in rails 2.0
  def beginning_of_month()  (self  - self.day + 1) end
  def end_of_month()        Date.new(self.year, self.month, -1)  end

  def beginning_of_year()   Date.new(self.year, 1, 1)  end
  def end_of_year()           Date.new(self.year, 12, 31) end

  def upto_bymonth(max  = Date.today)
    index = self
    begin
      yield index
      index = index >> 1
    end while (index < max)
  end

# This would be a cool way to do it, (DRY), but there's trickiness in passing a block around
#
# private
#
#   def upto_internal(max, unit, block)
#     index = self
#     begin
#       yield index
#       index = index >> unit
#     end while (index < max)
#   end
#
#   def upto_array_internal(max, unit, )
#     arr = []
#     self.upto_internal(max, unit) { | item| arr << item}
#     arr
#   end
#
# public
#   def upto_byyear(max = Date.today, &block)    upto_internal(max, 12, block)   end
#   def upto_bymonth(max = Date.today, &block)   upto_internal(max, 1, block )   end
#  
#   def upto_byyear_array(max = Date.today)  upto_array_internal(max, 12) end
#   def upto_bymonth_array(max = Date.today) upto_array_internal(max, 1 ) end

  
  def upto_bymonth_array(max  = Date.today)
    arr = []
    self.upto_bymonth(max) { |month| arr << month}
    arr
  end

  def upto_byyear(max = Date.today)
    index = self
    begin
      yield index
      index = index >> 12
    end while (index < max)
  end
  
  def upto_byyear_array(max = Date.today)
    arr = []
    self.upto_byyear(max) { |month| arr << month}
    arr
  end

    # Iterate through the nYears previous years PLUS the current year
  def each_prev_year(nYears)
    # Get first day of year nYears ago
    firstDayOfYear = ((Date.today - Date.today.yday) + 1) << (nYears * 12)
    while (firstDayOfYear <= Date.today)

      lastDayOfYear = (firstDayOfYear >> 12) - 1

      # Calculate number of days elapsed in current year
      if (Date.today.year == firstDayOfYear.year)
        days = (Date.today.yday - 1).to_f + (Time.now.hour.to_f / 24.0)
      else
        # Just count days in year
        days = ((lastDayOfYear + 1) - firstDayOfYear).to_f
      end

      # Callback with first day of year, last day of year and days elapsed in year
      yield(firstDayOfYear, lastDayOfYear, days, ((lastDayOfYear + 1) - firstDayOfYear).to_f)

      # Increment year
      firstDayOfYear = firstDayOfYear >> 12

    end
  end

  # Iterate through nQuarters previous quarters PLUS current quarter
  def each_prev_quarter(nQuarters)
    first = Date.today + 1 - Date.today.yday
    first = first >> 3 while (first <= Date.today)
    first = first << (3 * nQuarters)
    while(first <= Date.today)
      last = (first >> 3) - 1
      if last > Date.today
        days = ((Date.today - 1) - first).to_f + (Time.now.hour.to_f / 24.0)
      else
        days = ((last + 1) - first).to_f
      end
      yield first, last, days, ((last + 1) - first).to_f
      first = first >> 3
    end
  end

  # Iterate through each previous 2 month period, with the current month
  # always standing alone
  def each_prev_2month(nPeriods)
    first = ((Date.today - Date.today.day) + 1) << (nPeriods * 2)
    while (first <= Date.today)
      last = (first >> 2) - 1
      if last > Date.today
        days = (Date.today - first).to_f + (Time.now.hour.to_f / 24.0)
      else
        days = ((last + 1) - first).to_f
      end
      yield first, last, days, ((last + 1) - first).to_f
      first = first >> 2
    end
  end


  # Iterate through the nMonths previous months PLUS the current month
  def each_prev_month(nMonths)
    # Get first day of month nMonths ago
    firstDayOfMonth = ((Date.today - Date.today.day) + 1) << nMonths
    while (firstDayOfMonth <= Date.today)

      lastDayOfMonth = (firstDayOfMonth >> 1) - 1

      # Calculate (fractional) number of days elapsed in current month
      if (Date.today.year == firstDayOfMonth.year && Date.today.month == firstDayOfMonth.month)
        days = (Date.today - firstDayOfMonth).to_f + (Time.now.hour.to_f / 24.0)
      else
        # Just count days in month
        days = ((lastDayOfMonth + 1) - firstDayOfMonth).to_f
      end

      # Callback with first day of month, last day of month and days elapsed in month
      yield(firstDayOfMonth, lastDayOfMonth, days, ((lastDayOfMonth + 1) - firstDayOfMonth).to_f)

      # Increment month
      firstDayOfMonth = firstDayOfMonth >> 1

    end
  end

  # Same for weeks, eventually collapse this in with above
  def each_prev_week(nWeeks)
    # Get first day of week (Monday) nWeeks ago
    firstDayOfWeek = ((Date.today - Date.today.cwday) + 1) - (nWeeks * 7)
    while (firstDayOfWeek <= Date.today)

      lastDayOfWeek = firstDayOfWeek + 6

      # Calculate (fractional) number of days elapsed in current week
      if (Date.today.cweek == firstDayOfWeek.cweek)
        days = (Date.today - firstDayOfWeek).to_f + (Time.now.hour.to_f / 24.0)
      else
        # Just count days in week
        days = ((lastDayOfWeek + 1) - firstDayOfWeek).to_f
      end

      # Callback with first day of week, last day of week and days elapsed in week
      yield(firstDayOfWeek, lastDayOfWeek, days, ((lastDayOfWeek + 1) - firstDayOfWeek).to_f)

      # Increment week
      firstDayOfWeek = firstDayOfWeek + 7

    end
  end

  # Same for arbitrary number of days
  def each_prev_ndays(nDays, nPeriods)

    # Figure out the first day
    firstDay = Date.today - ((nPeriods * nDays) - 1)

    while (firstDay <= Date.today)
      lastDay = firstDay + (nDays - 1)
      days = (lastDay == Date.today) ? (nDays - 1).to_f + (Time.now.hour.to_f / 24.0) : nDays
      yield(firstDay, lastDay, days, nDays)
      firstDay += nDays
    end
  end

  # Calculate the first day of the current period, given the period selected

  def self.first_day_of_current_period(period)
    case period
    when "year" then
      return Date.today + 1 - Date.today.yday
    when "quarter"
      # Start with the first day of the year, add 3 months at a time
      # until in future, then subtract 3 months
      first = Date.today + 1 - Date.today.yday
      first = first >> 3 while (first <= Date.today)
      return first << 3
    when "week" then
      return Date.today + 1 - Date.today.cwday
    when /^[0-9]+$/
      return Date.today - (period.to_i - 1)
    else # month and 2month
      return Date.today + 1 - Date.today.day
    end
  end

  # Set of methods that return a date in relation to this date based on weekday
  { 'monday' => 0, 'tuesday' => 1, 'wednesday' => 2, 'thursday' => 3, 'friday' => 4, 'saturday' => 5, 'sunday' => 6 }.each do |day, incr|
    define_method("following_#{day}") do |*args|
      options = args.first.is_a?(Hash) ? args.shift : {}
      options.assert_valid_keys(:skip_current)
      result = self.beginning_of_week + incr
      result += 7 if (options[:skip_current] ? result <= self : result < self)
      result
    end
    define_method("previous_#{day}") do |*args|
      options = args.first.is_a?(Hash) ? args.shift : {}
      options.assert_valid_keys(:skip_current)
      result = self.beginning_of_week + incr
      result -= 7 if (options[:skip_current] ? result >= self : result > self)
      result
    end
  end

end

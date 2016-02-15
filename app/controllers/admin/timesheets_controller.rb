class Admin::TimesheetsController < Admin::Base

  def show

    # sanity check
    # 
    if (params[:date].nil?)
      redirect_to  :controller=>"persons", :action =>"show", :id=> params[:id]
      return
    elsif (params[:id].nil?)
      redirect_to  :controller=>"persons", :action =>"index"
      return
    end

    # who ?
    @person = Person.find(params[:id])
    
    # when ?  (if Monday supplied, use it - for any other, find the prev Monday)
    @week_begin = (Date.strptime(params[:date]) - (Date.strptime(params[:date]).cwday - 1))
    @week_end = @week_begin + 6

    # edittable ?
    #
    @editable = Array.new(7, false)
    @editable = Array.new(7, true) if (! session[:employee_number].nil? && Person.find(session[:employee_number]).authority_timesheet )
    @editable[Date.today - @week_begin] = true if
      ((Date.today - @week_begin) < 7) && 
      ((Date.today - @week_begin) >= 0) && 
      (! session[:employee_number].nil? && session[:employee_number].to_i == params[:id].to_i)

    # setup new timesheet (will not be saved if user abandons it...), pulldown menus
    #
	@hours = Array.new(24) { |index| index }.map { |val| [ val == 0 ? "midnight" : val == 12 ? "noon" : val < 12 ? "#{val} AM" : "#{val - 12} PM", val]}
	@mins = [0, 15, 30, 45].map { |val| [(0 == val) ? "00" : val.to_s, val]}
    @timesheet = Timesheet.new(params[:id], params[:date])
  end

  def index
    # Key day is two weeks before most recent Monday.
    # This lets us do payroll on a Tues and see the previous two weeks
    @key_day = (Date.today - Date.today.wday) -13

    # send over all timesheets ... for live people
    persons = Person.find(:all)
    @timesheets = Array.new
    @salaried = Array.new
    persons.select { |pp| pp.end_date.nil? || pp.end_date >= @key_day }.each do | pp |
      if (pp.hourlyP)
        @timesheets.push(Timesheet.new(pp, @key_day))
      else
        @salaried.push(pp)
      end
    end


  end

  def add
    tsi = TimesheetItem.create(:date => params[:date],
                               :percent_smartflix => 1.0,
                               :hr_person_id => params[:id])
    redirect_to  :action =>"show", :id=> params[:id], :date=>params[:display_date] 
  end

  def update
    @person = Person.find(params[:toplevel][:person_id])
    params[:begin_hr].each do | tsi_id, tsi_begin_hr |
      tsi_begin_min = params[:begin_min][tsi_id]
      tsi_end_hr = params[:end_hr][tsi_id]
      tsi_end_min = params[:end_min][tsi_id]

      tsi = TimesheetItem.find(tsi_id)
      tsi.begin = "#{tsi_begin_hr}:#{tsi_begin_min}:00"
      tsi.end = "#{tsi_end_hr}:#{tsi_end_min}:00"

      if ((tsi.begin <=> tsi.end ) == 0)
        tsi.destroy
      else
        tsi.save()
      end
    end
    url = url_for :action => "show" , :id=>@person,  :date=>params[:toplevel][:weekbegin]
   redirect_to url
  end
  
  
end


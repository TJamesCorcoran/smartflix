require "digest/sha1"

class Admin::PersonsController < Admin::Base
  def get_class() Person end

  def index
    params[:search_str] = "%" + params[:search_str].to_s + "%"
    conditions = params[:all] ? "" : "ISNULL(end_date) || end_date > NOW()"
    @persons = Person.find(:all, :conditions => conditions)
  end

  def login
    wannabe_person = Person.find(params[:id])
    begin
      flash[:error] = "bad password"
      redirect_to :action => :show, :id => params[:id]
      return
    end unless Digest::SHA1.hexdigest(params[:password]) == wannabe_person.oneway_hash_of_password
    flash[:notice] = "successful login"
    @person = wannabe_person
    session[:employee_number] = @person.id
    return redirect_to :action => :show, :id =>@person
  end

  def logout
    session[:employee_number] = @employee = nil
    redirect_to :action => :index
  end

  def show
    @person = Person.find(params[:id])
    @timesheet_dates = []
    (Date.today + 1 - Date.today.wday).step(Date.strptime("2007-05-28"), -7) do | dd | 
      @timesheet_dates.push(dd)
    end
  end

  def new
    begin
      flash[:error] = "no authority for this action"
      redirect_to :action => :index
    end unless (! session[:employee_number].nil? && Person.find(session[:employee_number]).authority_timesheet )

    @person = Person.new
  end

  def edit
    begin
      flash[:error] = "no authority for this action"
      redirect_to :action => :index
    end unless (! session[:employee_number].nil? && Person.find(session[:employee_number]).authority_timesheet )

    @person = Person.find(params[:id])
  end

  def create
    begin
      flash[:error] = "no authority for this action"
      redirect_to :action => :index
    end unless (! session[:employee_number].nil? && Person.find(session[:employee_number]).authority_timesheet )

    params[:person][:oneway_hash_of_password] = Digest::SHA1.hexdigest(params[:person][:password])
    params[:person].delete(:password)
    @person = Person.new(params[:person])
    @person.employee_number = Person.next_employee_number    if @person.employeeP
    if ( @person.save! )
      flash[:notice] = 'Person was successfully created.'
      redirect_to person_url(@person) 
    end
  end

  def update
    begin
      flash[:error] = "no authority for this action"
      redirect_to :action => :index
    end unless (! session[:employee_number].nil? && Person.find(session[:employee_number]).authority_timesheet )


    @person = Person.find(params[:eid])

    # update the password if-and-only-if it's been specified.  In any
    # case, delete it from params, bc it's not a real attribute of the
    # Person class.
    @person.oneway_hash_of_password = Digest::SHA1.hexdigest(params[:person][:password]) if params[:person][:password] != ""
    params[:person].delete(:password)

    params[:person][:password]
    if @person.update_attributes(params[:person])
      flash[:notice] = 'Person was successfully updated.'
      redirect_to :action => :show, :id => @person.id
    end
  end

end


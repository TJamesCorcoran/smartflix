class Admin::UspsPostageFormsController < ApplicationController

  layout 'masteredit'

  def setup
    @usps_forms = UspsPostageForm.find(:all, :limit => 10, :order => "created_at DESC")
    @most_recent = @usps_forms[0].created_at
    @shipments = Shipment.find(:all, :conditions => " boxP = 0 and dateOut > '#{@most_recent.strftime("%Y-%m-%d %H:%M:%S")}'").reject { |ship| ship.line_items.empty? }

    # fix the bug with amounts over 200
    @shipments = @shipments.select { |pack| pack.usps_type == :flat}
    delta =  @shipments.size - UspsPermitImprint::MIN_SHIPMENT_SIZE
    if delta > 0
      @shipments = @shipments[0, UspsPermitImprint::MIN_SHIPMENT_SIZE + ( delta / 2).to_i]
    end
  end
  
  def index
    # bc we're communicating between the frontend and backend server, we can't do AJAX,
    # can't do flash, etc.  We're passing the fake-flash msg in the URL...and that's ugly.
    #
    # Clean up the URL 
    if params[:fake_flash]
      flash[:notice] = params[:fake_flash]
      redirect_to :action => :index
    end

    setup
    @new_ps3600_allowedP = @shipments.size >= UspsPermitImprint::MIN_SHIPMENT_SIZE
    @num_shipments = @shipments.size
  end
  
  def print
    backend_only

    begin
      setup
      redirect_url = params["redirect_url"]
      person_id = params[:employee_number]
      path = UspsPermitImprint::generate_all_ps3600ez(@shipments)
      system("lp -d #{BACKEND_PRINTER_NAME} #{path}")
      # XYZFIX P4 - it'd be nice to not hardcode Julio's id in here ; need to pass it as an arg from view to here
      new_form = UspsPostageForm.create(:form_name => "ps 3600 ez", :person_id => 10)
      text = "<span style='color:green;'>form printed; recorded in db</span><br>"
   rescue
      text = "<span style='color:red;'>#{$!}</span><br>"
    end
    redirect_to redirect_url + "?fake_flash=" + text
  end

end

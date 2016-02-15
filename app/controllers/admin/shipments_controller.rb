class Admin::ShipmentsController < ApplicationController

  layout 'masteredit'

  def index
    if params[:search_str].nil?
      @shipments = Shipment.find(:all, :order => "shipment_id desc", :limit=>20)
    else
      @shipments = Shipment.find_all_by_shipment_id(params[:search_str].to_i)
      return redirect_to( :action => :show, :id => @shipments.first.id) if @shipments.size == 1
    end
  end

  def show
    @shipment = Shipment.find(params[:id])
  end

  def recalc
    # duplicate code - see lib/tvr/do.rb,     def self.recalc_shipping()
    spawn do
      Shipping.toplevel_recalc
    end
    flash[:notice] = 'Recalc running in background; page will reload in <span id=countdown></span> seconds. 
        <script type="text/javascript">
            seconds = (10 * 60)
            function countdown()
            {
              if (seconds == 0) { window.location.reload(); }
              $("countdown").innerHTML = seconds;
              seconds = seconds - 1;
            }
            setInterval("countdown()", 1000); 
        </script>'
    redirect_to :action => :ship
  end
  
  def ship
#RAILS3    web_only
    # bc we're communicating between the frontend and backend server, we can't do AJAX,
    # can't do flash, etc.  We're passing the fake-flash msg in the URL...and that's ugly.
    #
    # Clean up the URL 
    if params[:fake_flash]
      flash[:notice] = params[:fake_flash]
      redirect_to :action => :ship
    end
    @shipments = PotentialShipment.find(:all)
    @last_shipment = Shipment.find(:all, :order => "shipment_id desc", :limit => 1).first
  end

  def cancel
    begin
      @shipment = PotentialShipment.find(params[:id])
      @customer = @shipment.customer
      @shipment.cancel
      flash[:notice] = "shipment to #{@customer.full_name} cancelled"
    rescue Exception => e
      flash[:notice] = "ERROR! #{e.message}"
    end
    return redirect_to :action => :ship
  end
  
  def print
    backend_only if (Rails.env == 'production')

    # get an array of 1 shipment (if specified) or all shipments
    @shipments = PotentialShipment.find(params["print_id"] || :all).to_array
    redirect_url = params["redirect_url"]
    
    @shipments.reject do |s|
      if s.potential_items.empty?
        SfMailer.simple_message(SmartFlix::Application::EMAIL_TO_BUGS, SmartFlix::Application::EMAIL_FROM_AUTO, "Potential shipment with no items #{s.id}", "")
        true
      end
    end

    # sort labels in order that pullers want to pull
    #
    @shipments.sort_by { |potential_ship| potential_ship.sort_text }.each do |shipment|
      shipment.print_label
    end


    text = "<span style='color:green;'>printed #{@shipments.size} labels</span><br>"
    redirect_to redirect_url + "?fake_flash=" + text
  end


  def scan_out
    begin
      @barcode = params["barcode"]
      @potential_ship = PotentialShipment.find_by_barcode(@barcode)

      raise  "no such shipment #{@barcode}" if @potential_ship.nil?
      Shipping.make_potential_shipment_real(@potential_ship)
      return render :scan_out
    rescue Exception => e
      @msg = e.message
      return render :scan_out_error
    end
  end

  def lost_reorder
    shipment = Shipment.find(params[:id])
    shipment.mark_as_lost
    
    # generates 1 or more orders, broken up by uni, non-uni, etc.
    orders = Order.create_backend_replacement_order(shipment.customer, shipment.line_items)

    flash[:notice] = "shipment of #{shipment.copies.size} items marked as lost ; reordered as order #{orders.map(&:id).join(', ')}"
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end

  def lost_no_reorder
    shipment = Shipment.find(params[:id])
    shipment.mark_as_lost
    flash[:notice] = "shipment of #{shipment.copies.size} items marked as lost ; no reorder"
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end


end

class Admin::VendorOrderLogsController < Admin::Base

  def get_class() VendorOrderLog end

  # GET /vendor_order_logs/1;edit
  def edit
    @vendor_order_log = VendorOrderLog.find(params[:id])
    @purchasers = Purchaser.find(:all, :conditions=>"activeP = 1").map {|x| [ x.name_first + " " + x.name_last, x.id ]  }
  end

  # PUT /vendor_order_logs/1
  def update

    # find out quant, new quant
    #
    @vendor_order_log_new = @vendor_order_log = VendorOrderLog.find(params[:id])
    oldquant = @vendor_order_log.quant

    @vendor_order_log_new.attributes= params[:vendor_order_log]
    newquant = @vendor_order_log_new.quant

    # make sure that new order size won't push the number we're waiting for below 0
    #
    diff = oldquant - newquant
    iv = Product.find(@vendor_order_log.product_id).inventory_ordered
    iv.quant_dvd = iv.quant_dvd - diff

    if (iv.quant_dvd < 0)
      flash[:error] = 'can not push inventory ordered below 0'
      redirect_to :action=> :edit      
      return
    end

    # find new purchaser
    #
    @vendor_order_log.purchaser_id = params["purchaser"][:purchaser]

    iv.save()
    @vendor_order_log.save()
    flash[:notice] = 'VendorOrderLog was successfully updated.'
    redirect_to :controller=>"products", :id =>@vendor_order_log.product_id ,:action=> :show
  end


#  def index
#    @vendor_order_logs = VendorOrderLog.find(:all)
#
#    respond_to do |format|
#      format.html # index.rhtml
#    end
#  end
#
#  # GET /vendor_order_logs/1
#  def show
#    @vendor_order_log = VendorOrderLog.find(params[:id])
#
#    respond_to do |format|
#      format.html # show.rhtml
#    end
#  end
#
#  # GET /vendor_order_logs/new
#  def new
#    @vendor_order_log = VendorOrderLog.new
#  end


#  # POST /vendor_order_logs
#  def create
#    @vendor_order_log = VendorOrderLog.new(params[:vendor_order_log])
#
#    respond_to do |format|
#      if @vendor_order_log.save
#        flash[:notice] = 'VendorOrderLog was successfully created.'
#        format.html { redirect_to vendor_order_log_url(@vendor_order_log) }
#      else
#        format.html { render :action => "new" }
#      end
#    end
#  end

#  # DELETE /vendor_order_logs/1
#  def destroy
#    @vendor_order_log = VendorOrderLog.find(params[:id])
#    @vendor_order_log.destroy
#
#    respond_to do |format|
#      format.html { redirect_to vendor_order_logs_url }
#    end
#  end
end

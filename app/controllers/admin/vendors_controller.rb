class Admin::VendorsController < Admin::Base

  def get_class() Vendor end

  def stats
    @vendor = Vendor.find(params[:id])
    @status = Hash.new
    @vendor.products.each do |tt|
      tt.line_items.each do |li|
        date = li.order.orderDate.strftime("%Y-%m")
        if (@status[date].nil?) then @status[date] = 0 end
        @status[date] += 1
      end
    end
  end

  def interact
    # note that this method does not alter the vendor; it creates
    # new entries in the interactions table
    #
    @vendor = Vendor.find(params[:id])
    inter = VendorInteraction.new
    inter.interaction_date = DateTime.now.strftime("%Y-%m-%d")
    inter.vendor_id = params[:id]
    inter.vendor_interaction_kind_id = params[:kind]
    inter.url = params[:url]
    inter.save
    
    flash[:notice] = 'Interaction added.'
    redirect_to :action => 'show', :id => @vendor
  end

end

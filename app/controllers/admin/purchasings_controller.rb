class Admin::PurchasingsController < Admin::Base

  def index

    params[:vendorsort] ||= "pain"
    params[:verboseP]   ||= "false"
    params[:painMin]    ||= 0
    params[:univ]       ||= "false"

    @purchasers = Purchaser.find(:all, :conditions=>"activeP = 1").map {|x| [ x.name_first + " " + x.name_last, x.id ]  }
	@vendors =   Vendor.find(:all, :order => "name" ).map {|x| [ x.name, x.vendor_id ]  }
    @quant_choices =  [ [0, 0], [1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7], [8,8], [9,9], [10,10], [11,11], [12,12]]
    @tobuy = Tobuy.find(:all, :conditions => ["(quant > 0 ) AND pain >= ?", params[:painMin]])
    if params[:univ] == "true"
      @tobuy = @tobuy.select { |tb| tb.product.universities.any? }    
    end

    @polishable = Purchasing.polishable_hash
  end
  
  def polishable
    @polish_high = Purchasing.polishable_high
    @polish_med  = Purchasing.polishable_med
    @polish_low  = Purchasing.polishable_low

    @num_polished_today = Purchasing.polished_today.size
    @num_dead_today     = Purchasing.dead_today.size
  end

  def delayed_vendors
    @dvo = InventoryOrdered.delayed_vendor_orders
  end

  def update

    purchaser_id = params["purchaser"][:purchaser_id]
    purchaser = Purchaser.find(purchaser_id)

    total_ordered = 0
    VendorOrderLog.transaction do
      params.reject{ |kk,vv| kk !~ /^tobuy/}.each_pair do |product_id_raw, ordhash|

        match = product_id_raw.match(/^tobuy([0-9]*)$/)
        product_id = match[1].to_i
        purchased = ordhash[:quant].to_i
        next if (0 == purchased)
        
        # quant is positive, bc the number on order has increased
        vol = VendorOrderLog.create(:product_id => product_id, :orderDate => Date.today(), 
                                    :quant => purchased, :purchaser_id => purchaser_id)

        iv = Product.find(product_id).inventory_ordered
        if iv.nil?
          iv = InventoryOrdered.create!(:product_id => product_id, :quant_dvd => purchased)
        else
          iv.update_attributes(:quant_dvd => iv.quant_dvd + purchased)
        end

        total_ordered += purchased

        Product.find(product_id).update_tobuy
      end
    end
    
    flash[:notice] = "Purchasing by #{purchaser.full_name} updated: #{total_ordered} copies ordered"

    r_controller = params[:r_controller] || :purchasings
    r_action     = params[:r_action]     || :index
    r_id         = params[:r_id]         || nil
    redirect_to :controller=> r_controller, :action => r_action, :id=> r_id
  end

end

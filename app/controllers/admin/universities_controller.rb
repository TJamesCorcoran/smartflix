class Admin::UniversitiesController < Admin::Base

  def get_class() University  end

  def show
    @item = University.find(params[:id])
    @products_to_add = @item.category.products.select { |prod| prod.candidate_for_university?(@item) }.map { |prod| "#{prod.id}: #{prod.name}" }

    # purchasing stuff
    @purchasers = Purchaser.find(:all, :conditions=>"activeP = 1").map {|x| [ x.name_first + " " + x.name_last, x.id ]  }
    @quant_choices =  [ [0, 0], [1,1], [2,2], [3,3], [4,4], [5,5], [6,6], [7,7], [8,8], [9,9], [10,10], [11,11], [12,12]]
    @tobuy = Tobuy.find(:all, :conditions => ["pain >= ?", params[:painMin]])


  end

  def add_product
    # add the item to both the abstract university, ** AND ** to any subscriptions
    # that have items left in them
    univ = University.find(params[:id]) 
    product = Product.find(params[:product_to_add].split(":")[0])
    univ.add_product(product)
    
    # ... now tell folks that they've had items added, so that they can delete them 
    # XYZFIX P3: this happens during a web request
    orders = univ.orders_with_items
    orders.each do |o|
      begin
        SfMailer.university_item_added(o.customer, o.university, product)
      rescue Timeout::Error => e
        flash[:error] ||= ""
        flash[:error] += "; timeout sending to #{o.customer.email}"
      end

    end
    flash[:notice] = "added '#{product.name}' to #{univ.name} ; sent #{orders.size} emails"
    redirect_to :action => 'show', :id => params[:id]
  end

  def remove_product
    univ = University.find(params[:univ_id]) 
    product = Product.find(params[:product_id])
    univ.remove_product(product)
    flash[:notice] = "removed '#{product.name}' from #{univ.name}"
    redirect_to  :controller => params[:r_controller], :action => params[:r_action], :id => params[:r_id]
  end

end

class Admin::ProductBundlesController < Admin::Base
  def get_class() ProductBundle end

  def index
    @product_bundles = ProductBundle.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @product_bundles.to_xml }
    end
  end

  def show
    @product_bundle = ProductBundle.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @product_bundle.to_xml }
    end
  end

  def new
    @product_bundle = ProductBundle.new
    @titles = Title.find(:all).sort_by(&:name)
    @title_sets = Videoset.find(:all).sort_by(&:name)
  end

  def edit
    @product_bundle = ProductBundle.find(params[:id])
  end

  def create
    @product_bundle = ProductBundle.new(params[:product_bundle])
    update_titles(@product_bundle,params)

    respond_to do |format|
      if @product_bundle.save
        flash[:notice] = 'ProductBundle was successfully created.'
        format.html { redirect_to product_bundle_url(@product_bundle) }
        format.xml  { head :created, :location => product_bundle_url(@product_bundle) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @product_bundle.errors.to_xml }
      end
    end
  end

  def update
    @product_bundle = ProductBundle.find(params[:id])
    update_titles(@product_bundle,params)
    
    respond_to do |format|
      if @product_bundle.update_attributes(params[:product_bundle])
        flash[:notice] = 'ProductBundle was successfully updated.'
        format.html { redirect_to product_bundle_url(@product_bundle) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @product_bundle.errors.to_xml }
      end
    end
  end

  def destroy
    @product_bundle = ProductBundle.find(params[:id])
    @product_bundle.destroy

    respond_to do |format|
      format.html { redirect_to product_bundles_url }
      format.xml  { head :ok }
    end
  end

  def stats
    @bundles = ProductBundle.find(:all)
    @bundle_rentals = {}
    # Iterate through each bundle and see how many times it's been rented
    @bundles.each do |bundle|
      # Find orders that 1) contain all products in the bundle 2) have a
      # price on only one of the items in the bundle
      title_ids = bundle.titles.collect(&:title_id)
      joins = title_ids.inject([]) { |tables, id| tables << "lineItem li#{id}" }.join(',')
      conds = title_ids.inject([]) { |c, id| c << "orders.orderID=li#{id}.orderID AND li#{id}.title_id=#{id}" }.join(' AND ')
      orders = Order.find(:all, :joins => "JOIN #{joins}", :conditions => conds)
      orders = orders.select { |order| order.line_items.select { |li| title_ids.include?(li.title_id) && li.price > 0.0 }.size == 1 }
      @bundle_rentals[bundle.id] = orders.size
    end
  end
  
  private
  
  def update_titles(bundle,params)
    
    bundle.product_bundle_memberships.clear
    title_ids = params[:_results].split(' ') 
    title_ids.uniq!
    
    count = 0
    title_ids.each do |id|
      count += 1
      bundle.product_bundle_memberships << ProductBundleMembership.new(:product_id => id, :ordinal => count)
    end
  end
end

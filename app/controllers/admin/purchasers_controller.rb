class Admin::PurchasersController < Admin::Base
  def get_class() Purchaser end

  def index
    @purchasers = Purchaser.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @purchasers.to_xml }
    end
  end

  def show
    @purchaser = Purchaser.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @purchaser.to_xml }
    end
  end

  def new
    @purchaser = Purchaser.new
  end

  def edit
    @purchaser = Purchaser.find(params[:id])
  end

  def create
    @purchaser = Purchaser.new(params[:purchaser])

    respond_to do |format|
      if @purchaser.save
        flash[:notice] = 'Purchaser was successfully created.'
        format.html { redirect_to purchaser_url(@purchaser) }
        format.xml  { head :created, :location => purchaser_url(@purchaser) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @purchaser.errors.to_xml }
      end
    end
  end

  def update
    @purchaser = Purchaser.find(params[:id])

    respond_to do |format|
      if @purchaser.update_attributes(params[:purchaser])
        flash[:notice] = 'Purchaser was successfully updated.'
        format.html { redirect_to purchaser_url(@purchaser) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @purchaser.errors.to_xml }
      end
    end
  end

  def destroy
    @purchaser = Purchaser.find(params[:id])
    @purchaser.destroy

    respond_to do |format|
      format.html { redirect_to purchasers_url }
      format.xml  { head :ok }
    end
  end
end

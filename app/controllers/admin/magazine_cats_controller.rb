class Admin::MagazineCatsController < Admin::Base
  def get_class() MagazineCat end

  def setup
  end


  def index
    params[:search_str] = "%" + params[:search_str].to_s + "%"
    @magazinecat_pages, @magazinecat = paginate :magazine_cats, :per_page => 2000, :order => "string_code"
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @magazinecat.to_xml }
    end
  end

  def show
    @magazinecat = MagazineCat.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @magazinecat.to_xml }
    end
  end

  def new
    @magazinecat = MagazineCat.new
  end

  def edit
    setup
    @magazinecat = MagazineCat.find(params[:id])
  end

  def create
    setup
    @magazinecat = MagazineCat.new(params[:magazinecats])

    respond_to do |format|
      if @magazinecat.save
        flash[:notice] = 'MagazineCats was successfully created.'
        format.html { redirect_to magazinecats_url(@magazinecat) }
        format.xml  { head :created, :location => magazinecats_url(@magazinecat) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @magazinecat.errors.to_xml }
      end
    end
  end

  def update
    @magazinecat = MagazineCat.find(params[:id])

      if @magazinecat.update_attributes(params[:magazinecats])
        flash[:notice] = 'MagazineCats was successfully updated.'
        redirect_to magazinecats_url(@magazinecat) 
      else
        render :action => "edit" 
      end
  end

  def destroy
    @magazinecat = MagazineCat.find(params[:id])
    @magazinecat.destroy

    respond_to do |format|
      format.html { redirect_to magazinecats_url }
      format.xml  { head :ok }
    end
  end
end

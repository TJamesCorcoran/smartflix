class Admin::MagazinesController < Admin::Base
  def get_class() Magazine end

  def setup
	@categories = ["none", 0] + Category.find(:all, :order => "description" ).map {|x| [ x.full_name, x.catID ]  }.sort { |a,b| a[0] <=> b[0] }
  end


  def index
    params[:search_str] = "%" + params[:search_str].to_s + "%"
    @magazine_pages, @magazine = paginate :magazines, :per_page => 40, :order => "title", :conditions => ["title like ?", params[:search_str] ]



    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @magazine.to_xml }
    end
  end

  def show
    @magazine = Magazine.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @magazine.to_xml }
    end
  end

  def new
    setup
    @magazine = Magazine.new
  end

  def edit
    setup
    @magazine = Magazine.find(params[:id])
  end

  def create
    setup
    @magazine = Magazine.new(params[:magazine])

    respond_to do |format|
      if @magazine.save
        flash[:notice] = 'Magazines was successfully created.'
        format.html { redirect_to magazine_url(@magazine) }
        format.xml  { head :created, :location => magazine_url(@magazine) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @magazine.errors.to_xml }
      end
    end
  end

  def update
    @magazine = Magazine.find(params[:id])
      if @magazine.update_attributes(params[:magazine])
        flash[:notice] = 'Magazine was successfully updated.'
        redirect_to magazine_url(@magazine) 
      else
        render :action => "edit" 
      end
  end

  def destroy
    @magazine = Magazine.find(params[:id])
    @magazine.destroy

    respond_to do |format|
      format.html { redirect_to magazine_url }
      format.xml  { head :ok }
    end
  end
end

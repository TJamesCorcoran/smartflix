class Admin::OreillyCategoriesController < Admin::Base
  def get_class() OreillyCategory end

  def index
    params[:search_str] = "%" + params[:search_str].to_s + "%"
    @oreilly_categories = OreillyCategory.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @categories.to_xml }
    end
  end

  def show
    @oreilly_category = OreillyCategory.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @category.to_xml }
    end
  end

  def edit
    @oreilly_category = OreillyCategory.find(params[:id])
    @cats =  Category.find(:all, :order => "description" ).sort_by {|x| x.full_name}.map {|x| [ x.full_name, x.catID ]  }
  end

  def update

    @oreilly_category = OreillyCategory.find(params[:id])

    respond_to do |format|
      if @oreilly_category.update_attributes(params[:oreilly_category])
        flash[:notice] = 'Oreilly Category '#{@oreilly_category.display_name}' was successfully updated.'
        format.html { redirect_to :controller=>:oreilly_categories, :action=>:index }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @oreilly_category.to_xml }
      end
    end
  end

end

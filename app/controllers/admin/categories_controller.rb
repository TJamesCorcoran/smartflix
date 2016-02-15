class Admin::CategoriesController < Admin::Base

  def index
    @categories = Category.find(:all, :order => "description", :conditions => ["description like ?", "%" + params[:search_str].to_s + "%" ])
  end

  def show
    @category = Category.find(params[:id])
  end

  def new
    @category = Category.new
  end

  def edit
    @category = Category.find(params[:id])
  end

  def create
    @category = Category.new(params[:category])
    flash[:notice] = 'Category was successfully created.' if @category.save
    redirect_to category_url(@category) 
  end

  def update
    @category = Category.find(params[:id])
    
    if @category.update_attributes(params[:category])
      flash[:notice] = 'Category was successfully updated.'
      redirect_to category_url(@category) 
    else
      render :action => "edit" 
    end
  end
end

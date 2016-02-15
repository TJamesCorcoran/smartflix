class Admin::AuthorsController < Admin::Base
  def get_class() Author end


  def new
    @author = Author.new
  end

  def create
    @author = Author.new(params[:author])
    if @author.save
      flash[:notice] = "Author '#{@author.name}' (# #{@author.id}) was successfully created."
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @author = Author.find(params[:id])
  end

  def interact
    # note that this method does not alter the author; it creates
    # new entries in the interactions table
    #
    @author = Author.find(params[:id])
    inter = AuthorInteraction.new
    inter.interaction_date = DateTime.now.strftime("%Y-%m-%d")
    inter.author_id = params[:id]
    inter.author_interaction_kind_id = params[:kind]
    inter.url = params[:url]
    inter.save
    
    flash[:notice] = 'Interaction added.'
    redirect_to :action => 'show', :id => @author
  end

  def update
    @author = Author.find(params[:id])
    if @author.update_attributes(params[:author])
      flash[:notice] = 'Author was successfully updated.'
      redirect_to :action => 'show', :id => @author
    else
      render :action => 'edit'
    end
  end

  def destroy
    Author.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end

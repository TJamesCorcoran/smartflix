class ProjectsController < ApplicationController

  before_filter :require_customer, :only => [:new, :edit, :create, :update, :toggle_favorite_status]

  # Don't track lightbox views
  skip_before_filter :track_first_request, :store_browse_history, :track_origin,  :track_current_url, :only => [:image_lightbox]

  def index
    @projects = Project.find(:all)
  end

  def show
    @project = Project.find(params[:id])
    @crumbtrail = Breadcrumb.for_projects_show(@project)
  end

  def new
    @project = Project.new
    @project.inspired_by_id = params[:inspired_by_id] if params[:inspired_by_id]
    @project_update = ProjectUpdate.new
  end

  def edit
    @project = @customer.projects.find(params[:id])
  end

  def create
    @project = @customer.projects.build(params[:project])
    @project_update = @project.updates.build(params[:project_update])
    if @project.save
      @project_update.add_photos_from_form(params[:photos])
      flash[:message] = 'Project was successfully created.'
      redirect_to(@project)
    else
      render :action => "new"
    end
  end

  def update
    @project = @customer.projects.find(params[:id])
    if @project.update_attributes(params[:project])
      flash[:message] = 'Project was successfully updated.'
      redirect_to(@project)
    else
      render :action => "edit"
    end
  end

  def image_lightbox
    @photo = ProjectImage.find(params[:id])
    @photo = @photo.parent if @photo.parent
    render :layout => false    
  end

  def toggle_favorite_status
    @project = Project.find(params[:id])
    if @project.is_favorite_of?(@customer)
      @customer.favorite_projects.delete(@project)
    else
      @customer.favorite_projects << @project
    end
    respond_to do |wants|
      wants.html { redirect_to project_url(@project) }
      wants.js { render :partial => 'toggle_favorite_status.html.erb' }
    end
  end

end

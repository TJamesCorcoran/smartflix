class ProjectUpdatesController < ApplicationController

  before_filter :require_customer, :only => [:new, :edit, :create, :update, :delete_image]

  def new
    @project = @customer.projects.find(params[:project_id])
    @project_update = ProjectUpdate.new
  end

  def edit
    @project_update = @customer.project_updates.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.js { render :partial => 'form.html.erb', :locals => { :type => :update } }
    end
  end

  def create
    @project = @customer.projects.find(params[:project_id])
    @project_update = @project.updates.build(params[:project_update])
    if @project_update.save
      @project_update.add_photos_from_form(params[:photos])
      flash[:notice] = 'Project was successfully created.'
      redirect_to(@project)
    else
      render :action => "new"
    end
  end

  def update
    @project_update = ProjectUpdate.find(params[:id])
    raise 'Security violation! ProjectUpdate does not belong to current customer' if @project_update.project.customer != @customer
    if @project_update.update_attributes(params[:project_update])
      @project_update.add_photos_from_form(params[:photos])
      flash[:notice] = 'Project was successfully updated.'
      redirect_to(@project_update.project)
    else
      render :action => "edit"
    end
  end

  def delete_image
    @project_image = ProjectImage.find(params[:id])
    @project_image = @project_image.parent if @project_image.parent
    @project_update = @project_image.project_update
    raise 'Security violation! ProjectImage does not belong to current customer' if @project_update.project.customer != @customer
    @project_image.destroy
    respond_to do |wants|
      wants.html { redirect_to project_url(@project_update.project) }
      wants.js { render :partial => 'form.html.erb', :locals => { :type => :update } }
    end
  end

end

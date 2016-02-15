class CommentsController < ApplicationController

  before_filter :require_customer, :only => [:new, :edit, :create, :update]

  def new
    # The new comment placeholder is created in a partial
  end

  def edit
    @comment = @customer.comments.find(params[:id])
  end

  def create
    @comment = @customer.comments.build(params[:comment])
    if @comment.save
      flash[:message] = 'Comment was successfully added.'
      redirect_to(@comment.parent)
    else
      render :action => "new"
    end
  end

  def update
    @comment = @customer.comments.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:message] = 'Comment was successfully updated.'
      redirect_to(@comment)
    else
      render :action => "edit"
    end
  end

end

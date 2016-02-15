class ProfilesController < ApplicationController

  def show
    # Show customer profiles for anyone who's written a review, created
    # a project, or commented on something
    @profile_customer = Customer.find(params[:id])
    unless @profile_customer.reviews.count > 0 ||
        @profile_customer.projects.count > 0 ||
        @profile_customer.posts.count > 0 ||
        @profile_customer.comments.count > 0 ||
        @profile_customer.wiki_pages.count > 0
      redirect_with_message("User profile not found", { :controller => :store, :action => :index })
    end
  end

end

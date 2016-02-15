# Simple controller to report status of the app / mongrel instance
# without requiring a DB connection

class StatusController < ApplicationController

  # Skip all filters
  skip_before_filter :setup_customer, :store_browse_history, :track_origin, :redirect_clickthroughs, :track_first_request,  :track_current_url

  def index
    render :text => "SERVER OK [#{request.port}]"
  end

end

module UrlTracker

  @@url_tracker_errors = 0

  def track_current_url
    # bail if robot
    return true if (RobotTest.is_robot?(request))

    # bail if url is admin
    return true if (params[:controller].match(/^admin/))


    begin

      UrlTrack.create!(:session_id => request.session_options[:id],
                      :customer_id => @customer.andand.id,
                      :path        => request.path,
                      :controller  => params[:controller],
                      :action      => params[:action],
                      :action_id   => params[:id])
    rescue  Exception => e
      # better to lose data than to ever inconvenience the customer!
      ExceptionNotifier.deliver_exception_notification(e, self, request)
    end
    true
  end

  def map_customer_to_session(customer)
    customer_id = customer.class == Fixnum ? customer : customer.id
    ActiveRecord::Base.connection.execute("update #{UrlTrack.table_name} set customer_id = #{customer_id} where session_id = '#{request.session_options[:id]}'")
  end

  # Find the ids for the last n times that the customer did action X on controller Y
  # E.g. for SF, if he visited the pages for video 1, then video 2, then video 3, get [ 3, 2, 1 ]
  # E.g. for SF, if he visited the pages for category 10, then cat 20, then cat 30, get [ 30, 20, 10 ]
  def ids_for_last_n_customer_actions(customer, controller_str, action_str, n = nil )
    n ||= 10000
    customer_id = customer.is_a?(Fixnum) ? customer : customer.id
    UrlTrack.find_all_by_customer_id_and_controller_and_action(customer_id, controller_str, action_str, :order => "url_track_id desc", :limit => n).map {|urltrack| urltrack.action_id.to_i }.uniq
  end

  def url_tracks_for_customer(customer, n = nil)
    n ||= 10000
    customer_id = customer.is_a?(Fixnum) ? customer : customer.id
    UrlTrack.find_all_by_customer_id(customer_id, :order => "url_track_id desc", :limit => n)
  end


  def ids_for_last_n_session_actions(n, controller_str, action_str )
    UrlTrack.find_all_by_session_id_and_controller_and_action(request.session_options[:id], controller_str, action_str, :order => "url_track_id desc", :limit => n).map {|urltrack| urltrack.action_id.to_i }
  end


  def customer_details_first_controller(customer, controller_str)
    customer_id = customer.class == Fixnum ? customer : customer.id
    UrlTrack.find_by_customer_id_and_controller(customer.id, controller_str)
  end

end

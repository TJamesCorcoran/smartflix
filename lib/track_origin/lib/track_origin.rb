module TrackOrigin

  #==========
  # get stats on current customer
  #==========

  def current_ct
    session[:ct]    
  end

  def current_campaign
    raise "unimplemented"
  end

  def ctcode_to_campaign
    raise "unimplemented"    
  end
  

  #==========
  # set stats on current customer
  #==========

  def track_origin
    verbose = false

    begin
      puts "-----" if verbose
      puts "OOO-1" if verbose

      # bail if robot
      return true if (RobotTest.is_robot?(request, session))

      puts "OOO-3" if verbose

      # bail if internal
      if (Rails.env == 'production')
        http_host = (Rails.env == 'production') ? request.env['HTTP_X_FORWARDED_HOST'].to_s : request.env['HTTP_HOST'].to_s
        http_host.gsub!(/[^\/.:a-zA-Z0-9_-]/, '')
        return true if (request.referer.andand.match(/^https?:\/\/#{http_host}/))
      end

      # store this click-through 
      # (but don't delete! let the redirect code do that)
      ct_code = nil
      if (params[:ct])
        puts "OOO-3.5a #{params[:ct]}" if verbose
        ct_code = session[:ct] = params[:ct]
        session[:ct_timestamp] = Time.now

        
        unless ct_code.match(/af[0-9]+/) || Campaign.find_by_ct_code(ct_code)

          HiMailer.message(Rails.env == 'production' ? (Rails.application.class)::EMAIL_TO_BADDATA : (Rails.application.class)::EMAIL_TO_DEVELOPER,
                                 (Rails.application.class)::EMAIL_FROM_BUGS,
                                 "[#{SITE_ABBREV} DATA] unsupported CT code '#{ct_code}'",
                                 "customer went to url"+
                                 #   {request.url}" +
                                 "...which includes ct_code " +
                                 "   #{ct_code} " +
                                 "unknown in campaigns" +
                                 "\n\n\n" + 
                                 "Sent from #{__FILE__} line #{__LINE__}")
          
        end
      else
        puts "OOO-3.5b" if verbose
      end

      # delete old CTs
      if (session[:ct_timestamp] && session[:ct_timestamp] < Time.now - 2.days )
        session[:ct_timestamp] = session[:ct] = nil
      end

      # make sure we've got an origin, one way or another
      #
      @origin = nil
      if session[:origin_id]
        @origin = Origin.find_by_id(session[:origin_id])
        puts "OOO-4-a #{session[:origin_id]} // #{@origin.inspect}" if verbose
      else
        uri = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"


        @origin = Origin.create!(:referer => request.referer,
                                 :ct_code => ct_code,
                                 :first_uri => uri,
                                 :user_agent => request.user_agent.andand.downcase || "")
        session[:origin_id] = @origin.id
        puts "OOO-4-b #{@origin.id} // #{session[:origin_id]}" if verbose
      end

      # if at all possible, add customer ID to origin
      #
      if @origin && @origin.customer.nil? && session[:customer_id]
        puts "OOO-5-a #{@origin.inspect}" if verbose
        @origin.update_attributes(:customer_id => session[:customer_id])
        session[:origin_mapped] = true
      else
        puts "OOO-5-b #{@origin.inspect}" if verbose
      end


    rescue  Exception  => e
      # better to lose data than to ever inconvenience the customer!
      puts "OOO-E-1 #{e.message}" if verbose

      ExceptionNotifier::Notifier.exception_notification(request.env, 
                                                         e,
                                                         :data => {:message => "was doing something wrong"}).deliver

    rescue
      puts "OOO-E-2" if verbose
      # better to lose data than to ever inconvenience the customer!

      ExceptionNotifier::Notifier.exception_notification(request.env, 
                                                         Exception("unknown"),
                                                         :data => {:message => "was doing something wrong"}).deliver

    end
    true
  end

  # Filter that redirects to the same exact page, minus any clickthrough
  # tags; this should help prevent confusing google by minimizing the
  # number of aparently different pages that have the same content (ie
  # we want to tell google and similar engines that the ct= and non-ct=
  # versions of a page are the same.
  #
  # This MUST come after track_origin in the filter list

  def redirect_clickthroughs
    if (params[:ct])
      params.delete :ct
      headers["Status"] = "301 Moved Permanently"
      redirect_to params, :status => 301
    end
    return true
  end

  # Combination filter
  def track_origin_and_redirect
    track_origin && redirect_clickthroughs
  end

end

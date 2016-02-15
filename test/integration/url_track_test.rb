require File.dirname(__FILE__) + '/../test_helper'


class UrlTrackTest < ActionController::IntegrationTest
  
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  
  def setup
    UrlTrack.destroy_all
  end

  def test_basic      

    cust_a = customers(:bob)    
    cust_b = customers(:joe)
    cust_c = customers(:robq)
    
    
    #----------
    # send customer 1 in
    #    have this cust view products before login
    #----------
    
    
    # we don't want to store url tracks of variant URLS 
    #
    
    get("/store/?ct=af200001", {} )        
    
    assert_redirected_to(:action => :index)
    assert_equal(0,   UrlTrack.count)
    
    get("/store", {} )        
    assert_response :success
    assert_equal(1,   UrlTrack.count)
    assert_equal(UrlTrack.first.customer_id, nil)
    assert_equal(UrlTrack.first.path,        "/store")
    assert_equal(UrlTrack.first.controller,        "store")
    assert_equal(UrlTrack.first.action,        "index")
    assert_equal(UrlTrack.first.action_id,        nil)
    
    
    # Right now, we seem to store url tracks before we redirect to canonical URLs.
    # Doing the redirect first would be ideal, but this is good enough.
    # So, future sftwr maintainer - feel free to make the code better
    # and then make this test reflect that!
    #
    
    ret = get("/store/video/2", {} )        
    assert_redirected_to("/store/video/2/Product2")
    ret = get("/store/video/2/Product2", {} )        
    assert_equal(3                         , UrlTrack.count)
    assert_equal(nil                       , UrlTrack.last.customer_id)
    assert_equal("/store/video/2/Product2" , UrlTrack.last.path)
    assert_equal("store"                   , UrlTrack.last.controller)
    assert_equal("video"                   , UrlTrack.last.action)
    # XYZFIX P3 - this .to_i shouldn't be necessary ... do we want to do a
    # migration to make the action_id col an int?
    assert_equal(2                         , UrlTrack.last.action_id.to_i)
    
    
    #----------
    # log customer 1 in ; should patch all prev url tracks
    #----------
    
    util_login(cust_a.email, "password")
    
    num_tracks = 0
    UrlTrack.find(:all).each { |ut|
      assert_equal(ut.customer_id, cust_a.customer_id)
      num_tracks += 1
    }
    assert_equal(cust_a.url_tracks.size, num_tracks)
    
    
    
    
    #----------
    # send customer 2 in
    #    have this cust login before view products
    #----------
    
    # reset the session
    reset!
    
    get("/store", {} )        
    util_login(cust_b.email, "password")
    ret = get("/store/video/6/Product6", {} )            
    
    # we return url_tracks sorted - most recent first
    last_track = cust_b.url_tracks.first
    assert_equal(cust_b.customer_id        , last_track.customer_id)
    assert_equal("store"                   , last_track.controller)
    assert_equal("video"                   , last_track.action)
    assert_equal(6                         , last_track.action_id.to_i)
    
    # UrlTrack.find(:all).each { |ut| puts ut.inspect }
    
    assert_equal(7, cust_a.url_tracks.size)
    assert_equal(6, cust_b.url_tracks.size)

    assert_equal(cust_b.url_track_ids_for_controller_action("store", "video"), [6])
    assert_equal(cust_b.browsed_but_not_rented_or_recoed, [Video[6]])

    #----------
    # send customer 3 in
    #    login, but don't view any products.
    #    later, they should ** NOT ** show up in the Customer.customers_with_browsed_items
    #----------
    
    # reset the session
    reset!
    
    util_login(cust_c.email, "password")


    #----------
    # check that
    #   Customer.customers_with_browsed_items()
    # is working - it's based on url_tracks
    #----------

    assert_equal([cust_a, cust_b].to_set, Customer.customers_with_browsed_items.to_set)

    ret = get("/store/video/6/Product6", {} ) 
    ret = get("/store/video/7/Product6", {} ) 

    assert_equal([cust_a, cust_b, cust_c].to_set, Customer.customers_with_browsed_items.to_set)

    # UrlTrack.find(:all).each { |ut| puts ut.inspect }

    assert_equal(cust_a.browsed_videos.to_set, [Video[2]].to_set)
    assert_equal(cust_b.browsed_videos.to_set, [Video[6]].to_set)
    assert_equal(cust_c.browsed_videos.to_set, [Video[6],Video[7]].to_set)

  end

  
  def test_admin      

    cust_a = customers(:bob)    
    
    #----------
    # send customer 1 in
    #----------
    
    get("/admin/", {} )        
    
    assert_equal(0,   UrlTrack.count)

  end

  def test_robot     

    # in testing, the user_agent is 
    robot_list_orig = RobotTest.robot_list
    RobotTest.robot_list=[nil]

    begin
      
      cust_a = customers(:bob)    
      
      #----------
      # send customer 1 in with a browser that matches the robot_list
      #----------

      
      ret = get("/store/", {} )        

      # we got a page, but we didn't leave a url_track
      assert_response :success
      assert_equal(0,   UrlTrack.count)
      
    ensure
      RobotTest.robot_list= robot_list_orig
    end

  end

  
end

require File.dirname(__FILE__) + '/../test_helper'
require 'univstore_controller'

# Re-raise errors caught by the controller.
class UnivstoreController; def rescue_action(e) raise e end; end

class UnivstoreControllerTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  def setup
    @controller = UnivstoreController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
#    @emails = ActionMailer::Base.deliveries
#    @emails.clear
  end

  # Index doesn't do much, should return success
  def test_index  
    get :index
    assert_response :success
    assert_template 'index'
  end

  # how_it_works doesn't do much, should return success
  def test_how_it_works  
    get :how_it_works
    assert_response :success
    assert_template 'how_it_works'
  end

  # all doesn't do much, should return success
  def test_all  
    get :all
    assert_response :success
    assert_template 'all'


  end

  def test_one  
    get :one
    assert_redirected_to :action => 'all'
    assert_equal(nil, assigns(:univ))
    
    get :one, :univ_id => 1
    assert_response :success
    assert_template 'one'
    assert_equal(University.find(1), assigns(:univ))
    
    get :one, :univ_id => 2
    assert_response :success
    assert_template 'one'
    assert_equal(University.find(2), assigns(:univ))
    
    get :one, :univ_id => 299999
    assert_redirected_to :action => 'all'
    assert_equal(nil, assigns(:univ))
  end

  def test_signup_just_univ  

    # first view of page: nothing set
    get :all
    assert_template 'all'
    assert_equal(nil, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a nil univ - no effect
    post(:new_signup,
         { :university => { :university_id => nil},
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'all'
    assert_equal(nil, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a bad univ  - no effect
    post(:new_signup,
          { :university => { :university_id => 999},
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'all'
    assert_equal(nil, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a good univ - redirects back, bc no customer set
    post(:new_signup,
         { :university => { :university_id =>  University.find(:first).id },
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'all'
    univ = University.find(:first)
    assert_equal(nil, assigns(:customer))

    get(:all)
    assert_equal(univ, assigns(:univ_choice))    
    
    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a customer - now onward, bc both conditions met
    post(:new_signup,
         { :customer => { :email => "test@smartflix.com",
                          :email_2 => "test@smartflix.com",
                          :password => "12345",
                          :password_2 => "12345"},
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'set_address'
    cust = Customer.find_by_email("test@smartflix.com")
    univ = University.find(:first)
    assert_equal(cust, assigns(:customer))    
    assert_equal(univ, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    
  end

  def test_signup_just_customer  
    # first view of page: nothing set
    get :all
    assert_template 'all'
    assert_equal(nil, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    
    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a nil customer - no effect
    post(:new_signup,
         { :customer => { },
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'all'
    assert_equal(nil, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a bad customer  - no effect
    post(:new_signup,
          { :customer => { :email => "123",
                           :email_2 => "xyz"},
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'all'
    assert_equal(nil, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a good customer - redirects back, bc no univ set
    post(:new_signup,
         { :customer => { :email => "test@smartflix.com",
                          :email_2 => "test@smartflix.com",
                          :password => "12345",
                          :password_2 => "12345"},
            :src_controller => :univstore,
            :src_action     => :all,
            :src_id         => nil} )
         
    assert_redirected_to :action => 'all'
    cust = Customer.find_by_email("test@smartflix.com")
    assert_equal(cust, assigns(:customer))    
    assert_equal(nil, assigns(:univ_choice))    

    assert_equal(nil, assigns(:univ))    
#    assert_equal(University.most_popular(20), assigns(:univs))    

    # post a univ - now onward, bc both conditions met

    post(:new_signup,
         { :university => { :university_id =>  University.find(:first).id },
           :src_controller => :univstore,
           :src_action     => :all,
           :src_id         => nil} )

    assert_redirected_to :action => 'set_address'
    cust = Customer.find_by_email("test@smartflix.com")
    univ = University.find(:first)
    assert_equal(cust, assigns(:customer))  

    get(:pick_how_many_dvds)
    assert_equal(cust, assigns(:customer))  
    assert_equal(univ, assigns(:univ_choice))    
#    assert_equal(University.most_popular(20), assigns(:univs))    
  end


end

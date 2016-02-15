require File.dirname(__FILE__) + '/../test_helper'
require 'affiliate_controller'

# Re-raise errors caught by the controller.
class AffiliateController; def rescue_action(e) raise e end; end

class AffiliateControllerTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup
    @controller = AffiliateController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index

    # Make sure login is required
    get :index
    assert_redirected_to :controller => 'customer', :action => 'login'
    assert_equal "Login is required", flash[:message]

    # Make sure redirects to right place if not affiliate
    get :index, {}, {:customer_id => 1, :timestamp => Time.now.to_i}
    assert_redirected_to :controller => 'affiliate', :action => 'agreement'

    # Make sure OK if affiliate
    get :index, {}, {:customer_id => 2, :timestamp => Time.now.to_i}
    assert_response :success
    assert_template 'index'

  end

  # Make sure the agreement page responds
  def test_agreement

    # Make sure just responds if not yet affiliate
    get :agreement, {}, {:customer_id => 1, :timestamp => Time.now.to_i}
    assert_response :success
    assert_template 'agreement'

    # Make sure allows affiliate signup
    assert(!Customer.find(1).affiliate)
    post :agreement, {:commit => 'Accept Agreement'}, {:customer_id => 1, :timestamp => Time.now.to_i}
    assert_redirected_to :controller => 'affiliate', :action => ''
    assert(Customer.find(1).affiliate)

    # Make sure signed up affiliates just get redirect
    get :agreement, {}, {:customer_id => 1, :timestamp => Time.now.to_i}
    assert_redirected_to :controller => 'affiliate', :action => ''

  end

  # Make sure the introduction page responds
  def test_introduction
    get :introduction, {}, {:customer_id => 2, :timestamp => Time.now.to_i}
    assert_response :success
    assert_template 'introduction'
  end

end

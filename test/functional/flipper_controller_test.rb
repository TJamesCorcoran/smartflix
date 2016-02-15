require File.dirname(__FILE__) + '/../test_helper'
require 'flipper_controller'

# Re-raise errors caught by the controller.
class FlipperController; def rescue_action(e) raise e end; end

class FlipperControllerTest < ActionController::TestCase
  
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  def setup
    @controller = FlipperController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def standard_session
    { :flipper => { 1 => 0,
                    2 => 0,
                    3 => 'minimized' } }
  end

  # Replace this with your real tests.
  def test_index
    get :index, nil, standard_session
    
    assert_response :success
    assert_equal session[:flipper], { 1 => 0,
                                      2 => 0 }  # 3 is missing because it's 'sticky' is set to false
  end
  
  def test_close
    get :close, {:id => 1}, standard_session
    assert_response :success
    assert_equal  session[:flipper], {  1 => 'closed',
                                        2 => 0,
                                        3 => 'minimized' }
  end
  
  def test_minimize
    get :minimize, {:id => 1}, standard_session
    assert_response :success
    assert_equal  session[:flipper], {  1 => 'minimized',
                                        2 => 0,
                                        3 => 'minimized' }
  end
  
  def test_next
    get :next, {:id => 1}, standard_session
    assert_response :success
    assert_equal  session[:flipper], {  1 => 1,
                                        2 => 0,
                                        3 => 'minimized' }
  end
  
  def test_previous
    get :previous, {:id => 1}, standard_session
    assert_response :success
    assert_equal  session[:flipper], {  1 => 1,
                                        2 => 0,
                                        3 => 'minimized' }
  end
  
  def test_switch
    get :switch, {:id => 1, :n => 1}, standard_session
    assert_response :success
    assert_equal  session[:flipper], {  1 => 1,
                                        2 => 0,
                                        3 => 'minimized' }
  end
  
end

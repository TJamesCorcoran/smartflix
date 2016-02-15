require File.dirname(__FILE__) + '/../test_helper'
require 'profiles_controller'

# Re-raise errors caught by the controller.
class ProfilesPagesController; def rescue_action(e) raise e end; end

class ProfilesTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup
    @controller = ProfilesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show_no_content
    get :show, :id => customers(:four).to_param
    assert_redirected_to :controller => :store,  :action => :index
  end

  def test_show_some_content
    get :show, :id => customers(:bob).to_param
    assert_response :success
  end

end

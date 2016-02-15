require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsPagesController; def rescue_action(e) raise e end; end

class ProjectsTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup

    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @title1 = "Test Project 1"
    @text1 = "Test Project 1 Text"
    @project1 = Customer.first.projects.build(:status => 1, :title => @title1)
    @project_update1 = @project1.updates.build(:text => @text1)
    @project1.save

    @title2 = "Test Project 2"
    @text2a = "Test Project 2 Text A"
    @text2b = "Test Project 2 Text B"
    @project2 = Customer.first.projects.build(:status => 1, :title => @title2)
    @project_update2a = @project2.updates.build(:text => @text2a)
    @project_update2b = @project2.updates.build(:text => @text2a)
    @project2.save

  end

  def test_index
    get :index
    assert_response :success
    assert_equal(3, assigns(:projects).size) # Two created above, one from fixture
    assert(assigns(:projects).include?(@project1))
    assert(assigns(:projects).include?(@project2))
  end

  def test_show
    [@project1, @project2].each do |project|
      get :show, :id => project.to_param
      assert_response :success
      assert_equal(project, assigns(:project))
    end
  end

end

require File.dirname(__FILE__) + '/../test_helper'
require 'survey_controller'

# Re-raise errors caught by the controller.
class SurveyController; def rescue_action(e) raise e end; end

class SurveyControllerTest < ActionController::TestCase
  include ApplicationHelper
  include ActionView
  
  def setup
    @controller = SurveyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_answer_survey
    @request.session[:customer_id] = 1
    post :answer, :survey_question => {'1' => '7'}
    
    assert_response :redirect
    assert_equal "Thank you for participating.", flash[:message]
    assert_equal 3, Customer.find(1).survey_answers.size
  end
  
  def test_answer_survey_bad
    @request.session[:customer_id] = 1
    post :answer, :survey_answer => 'something'
    
    assert_response :redirect
    assert_equal "Thank you for participating.", flash[:message]
    assert_equal 2, Customer.find(1).survey_answers.size
  end
  
  def test_answer_survey_blank
    @request.session[:customer_id] = 1
    post :answer
    
    assert_response :redirect
    assert_equal "Thank you for participating.", flash[:message]
    assert_equal 2, Customer.find(1).survey_answers.size
  end
  
  def test_answer_survey_get
    @request.session[:customer_id] = 1
    get :answer, :survey_answer => {'1' => '7'}
    
    assert_response :redirect
    assert_equal 2, Customer.find(1).survey_answers.size
  end
  
end

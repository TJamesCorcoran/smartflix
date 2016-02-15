class SurveyController < ApplicationController
  
  # Surveys POST to this action.  Just a :survey_question entry in the params hash, which is itself
  #  a hash of: survey_question_id => answer
  #
  # post :answer, :survey_question => { :1 => '7', '3' => 'blue', ...}
  def answer
    if request.post?
      (params[:survey_question] || {}).each do |key,value|
        SurveyAnswer.create :survey_question_id => key.to_i, :answer => value.to_s, :customer_id => @customer.id, :order_id => params[:order_id]
      end
      flash[:message] = 'Thank you for participating.'
    end
    flash.keep(:order_id)
    redirect_to_previous(:controller => 'cart', :action => 'order_success')
  end
end

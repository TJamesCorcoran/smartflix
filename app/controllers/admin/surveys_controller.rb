class Admin::SurveysController < Admin::Base
  def get_class() Survey end

  def index
    @customer_history = Hash.new
    @failing = Survey.find_failing_and_unaddressed
    if (0 == @failing.size) then return end
    survey_question_id = @failing[0].survey_question.id
    @failing.each do |ff|
      customer_id = ff.customer.id
      history = Array.new
      ff.customer.survey_answers.select { |sa| 1 == survey_question_id }.sort_by{|ans| ans.created_at}.each do |ans|
        history.push(ans.answer)
      end
      @customer_history[ customer_id ] = history
    end

    @contact_types = CustomerContactType.find(:all)
  end

end

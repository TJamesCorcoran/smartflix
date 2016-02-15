module ActsAsAbTesterApplicationController

  def acts_as_abt_application_controller
    
    before_filter :set_abtest_session
    define_method(:set_abtest_session) do

      # functional tests don't have a session on hand
      #
      unless Rails.env == 'test'
        session[:ab_test_visitor_id] = params[:abtvid] if params[:abtvid] 
      end

    end
  end

end

ActionController::Base.extend ActsAsAbTesterApplicationController

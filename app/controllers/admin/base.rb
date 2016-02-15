# require 'acts_as_notable_controller'
# require 'acts_as_auto_admin_controller'

module Admin
  
  class Base < ApplicationController

    layout 'masteredit'
    
    http_basic_authenticate_with :name => SmartFlix::Application::SF_AUTH_ADMIN[:user], :password => SmartFlix::Application::SF_AUTH_ADMIN[:pwd]
    
    unloadable
    
    # this is where all the controller methods are
    #  (index, show, edit, etc.)
    acts_as_auto_admin_controller
    
    # allows us to add notes to this item
    #
    acts_as_notable_controller
    
   
    
    before_filter :setup_employee
    def setup_employee
      @employee = Person.find_by_person_id(session[:employee_number])  
    end
    
  end
  
end


module ActsAsNotableController

  def acts_as_notable_controller

    define_method(:add_note) do 
      begin
        @item = get_class.find(params[:id].to_i)
        
        emp = defined?(@employee) ? @employee : Customer.first
        @item.add_note( params[:text],  emp) # - would be nice to have employee id here
        flash[:message] = "note added"
      rescue Exception  => e
        flash[:error] = e.message
      end
      return redirect_to :back
    end


  end
end


# make this method available to all controllers
ActionController::Base.extend ActsAsNotableController

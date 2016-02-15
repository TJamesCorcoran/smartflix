class NewsletterEditor
  module CustController
    
    #----------
    # customer facing
    #----------
    def index
      @admin = false
      render :layout => false
    end
    
    def show
      @admin = false
      @newsletter = Newsletter.find_by_id(params[:id])
      unless @newsletter
        flash.now[:message] = "newsletter not found"
        return redirect_to :action => "index"
      end
      @index_link = true
      render :layout => false
    end
    
  end
end

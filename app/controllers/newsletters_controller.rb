class NewslettersController < ApplicationController
  include NewsletterEditor::CustController

  # SmartFlix:
  # override default because some search engine has links to old broken newsletters
  def show
    @admin = false
    id = params[:id].to_i
    return redirect_to :action => :index if id < 224 
    @newsletter = Newsletter.find(id)
    @index_link = true
    render :layout => false
  end

end

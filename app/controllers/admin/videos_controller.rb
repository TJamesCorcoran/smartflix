# bc of introspection-based / programatically generated common admin
# views, we need this ... but just redirect to products


class Admin::VideosController < Admin::Base

  def index
    return redirect_to :controller => :products, :action => :index
  end

  def show
    redirect_to :controller => :products, :action => :show, :id => params[:id]
  end

end

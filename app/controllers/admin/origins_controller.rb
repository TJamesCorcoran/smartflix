class Admin::OriginsController < Admin::Base
  def get_class() Origin end
  
  def show
    @origin = Origin.find(params[:id])
  end

end

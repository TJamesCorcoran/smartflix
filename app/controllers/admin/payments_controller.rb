class Admin::PaymentsController < Admin::Base
  def get_class() Payment end

  def index
    if (! params[:search_str].nil?)
      @payment = Payment.find(params[:search_str])
      redirect_to :action => :show, :id =>@payment
      return
    end
    @class = Payment
    @items = []
  end

  def show
    @class = Payment
    @item = Payment.find(params[:id])
  end

end

class Admin::CreditCardsController < Admin::Base
  def get_class() CreditCard end

  def index
    @items = CreditCard.find(:all)
  end

  def show
    @item = CreditCard.find(params[:id])
  end

  def try_again
    @cc = CreditCard.find(params[:id])
    @cc.incr_extra_attempts
    flash[:message] = "Thanks; we'll try your card (#{@cc.name}) again tomorrow."
    return redirect_to :back 
  end

end

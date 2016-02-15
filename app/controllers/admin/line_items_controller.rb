class Admin::LineItemsController < Admin::Base
  def get_class() LineItem end

  def univ_doesnt_count
    lineitem = LineItem.find(params[:id])
    lineitem.univ_doesnt_count!
    flash[:notice] = "lineitem #{params[:id]} ignored for univ"
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end

  def cancel
    lineitem = LineItem.find(params[:id])
    begin 
      lineitem.cancel
      flash[:notice] = "lineitem #{params[:id]} cancelled"
    rescue
      flash[:error] = "error when attempting to cancel LI - not cancelled"
    end

    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end

  def cancel_multiple

    # sanity checking
    if params[:li_ids].nil?
      flash[:error] = "no line items specified"
      return redirect_to(:controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id])
    end      
    
    begin 
      lineitems = params[:li_ids].keys.map { |key| LineItem.find(key.to_i)}
      uncancellable = lineitems.select { |li| ! li.cancellable? }
      msg = ""
      #     if uncancellable.any? 
      #       if uncancellable.reject { |li| cancellable?(true) }.any?
      #         flash[:error] = "LI #{lineitems.map(&:line_item_id).join(',')} not cancellable ; nothing cancelled"        
      #         redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
      #       else
      #         msg = "- *** in shipping; alert Julio"
      #       end
      #     end
      
      
      LineItem.transaction do
        lineitems.each { |li| li.cancel }
        flash[:notice] = "lineitems #{lineitems.map(&:line_item_id).join(',')} cancelled #{msg}"
      end
    rescue
      flash[:error] = "error when attempting to cancel LIs - none cancelled"
    end
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end

  def uncancel
    lineitem = LineItem.find(params[:id])
    lineitem.uncancel
    flash[:notice] = "lineitem #{params[:id]} uncancelled"
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end

  def give_grace
    lineitem = LineItem.find(params[:id])
    days = (params[:days]).to_i
    days = 7 if days == 0
    lineitem.grace(days)
    flash[:notice] = "grace granted to line_item #{lineitem.id}"
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end

  def refund
    lineitem = LineItem.find(params[:id])
    success, details = lineitem.refund
    if success
      flash[:notice] = "refund issued for $#{lineitem.price} for line_item #{lineitem.id} - credit card x#{details}"
    else
      flash[:error] = "failed to refund $#{lineitem.price} for line_item #{lineitem.id} - #{details}"
    end
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end
end

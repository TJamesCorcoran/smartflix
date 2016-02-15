class Admin::CustomersController < Admin::Base
  def get_class() Customer end

  def index
    @customers = []
    if ! params[:search_str].nil?
      params[:search_str] = "%" + params[:search_str].to_s + "%"
      @customers = Customer.find_by_sql(["SELECT customers.* 
                                          FROM customers, addresses 
                                          WHERE customers.shipping_address_id = addresses.address_id 
                                          AND ((email like ?) or (concat(addresses.first_name, ' ', addresses.last_name) like ?))", 
                                      params[:search_str], 
                                      params[:search_str]])
      if @customers.size == 1
        redirect_to :action => :show, :id => @customers.first.customer_id 
        return
      end
    elsif (! params[:fday].nil?)
      @fday = params[:fday]
      @lday = params[:lday] ||= Date.today
      @source = params[:source].to_sym_clean
      @customers = 
        case @source
          when :direct then       Origin.customers_direct(       @fday,@lday,false)    
          when :otherreferer then Origin.customers_other(        @fday,@lday,false)    
          when :googlesearch then Origin.customers_google_search(@fday,@lday,false)
          when :googlead then     Origin.customers_google_ads(   @fday,@lday,false)
          else raise "illegal #{@source.to_s}"
        end
    end
  end

  # Give customer support a way to do a screen shot of a customer's 
  # cart, to fight chargebacks
  #
  #
  helper :cart
  def checkout_screen_shot

    @order = Order.find(params[:order_id].to_i)
    @customer = @order.customer
    @cart =  Cart.create
    lis = @order.line_items
    prods = []
    if @order.university
      prods = [@order.university.univ_stub]
    else
      prods =  lis.map(&:product)
    end
    prods.each do |product|
      @cart.add_product(product, :override_unavail => true, :override_dup => true)
    end
    @usable_account_credit = 0.0
    render "cart/checkout",   :layout => 'checkout', :method => :post
  end

  def show
    @customer = Customer.find(params[:id].to_i)
    @happiness = @customer.happiness_history
  end

  def add_note
    begin
      @customer = Customer.find(params[:id].to_i)
      raise "must be logged in" unless @employee
      @customer.add_note( params[:text],  @employee.id)
      flash[:message] = "note added"
    rescue Exception  => e
      flash[:error] = e.message
    end
    return redirect_to :back
  end

  def delay_text
    @customer = Customer.find(params[:id])
  end

  def throttle
    Customer.find(params[:id]).throttle
    flash[:notice] = "customer throttled"    
    redirect_to :action => :show, :id =>params[:id] 
  end

  def no_addr
    cnt = Customer.find(params[:id]).no_addr!
    flash[:notice] = "#{cnt} copies marked as dead; cust throttled"    
    redirect_to :action => :show, :id =>params[:id] 
  end

  def lawsuit_filed
    begin
      cnt = Customer.find(params[:id]).lawsuit_filed!
      flash[:notice] = "lawsuit for #{cnt.size} copies filed"    
    rescue Exception => e
      flash[:error] = e.message
    end
    redirect_to :action => :show, :id =>params[:id] 
  end

  def unthrottle
    Customer.find(params[:id]).unthrottle
    flash[:notice] = "customer unthrottled"    
    redirect_to :action => :show, :id =>params[:id] 
  end

  def mark_copy_defective_and_reship
    li = LineItem.find(params[:id])
    msg = params[:msg]
    copy = li.copy
    copy.mark_as_scratched(msg)
    orders = Order.create_backend_replacement_order(li.order.customer, [li])
    flash[:notice] = "reordered as order #{orders.map(&:id).join(', ')}"
    redirect_to :controller=>params[:r_controller], :action =>params[:r_action], :id=>params[:r_id]
  end


  def cancel_order
    begin
      flash[:error] = "no authority for this action"
      return(redirect_to :action => :show, :id => params[:customer_id] )
    end unless ( session[:employee_number] && Person.find(session[:employee_number]).authority_cancel_univ_order )

    
    Order.find(params[:id]).andand.cancel(true)
    flash[:notice] = "order #{params[:id]} cancelled"
    redirect_to :action => :show, :id =>params[:customer_id] 
  end

  # cut-and-paste programming
  #     see also app/controllers/customer_controller.rb
  #
  def reinstate_order
    begin
      flash[:error] = "no authority for this action"
      return(redirect_to :action => :show, :id => params[:customer_id] )
    end unless ( session[:employee_number] && Person.find(session[:employee_number]).authority_cancel_univ_order )

    Order.find(params[:id]).andand.reinstate
    flash[:notice] = "order #{params[:id]} reinstated"
    redirect_to :action => :show, :id =>params[:customer_id] 
  end

  def update_dvd_rate
    customer = Customer.find(params[:customer_id])

    rate = params[:rate].to_i
    
    customer.ship_rate = rate
    customer.save!
    flash[:message] = "updated ship rate to #{rate}"
    redirect_to :action => :show, :id =>params[:customer_id]     
  end

  def credit_customer_account

    customer = Customer.find(params[:customer_id])
    amount = params[:amount]
    months = params[:months]



    if  (months.nil? || months.to_i == 0) &&
        (!amount.match(/^-?[0-9]+(\.[0-9][0-9])?$/) || amount.to_f == 0.0) 
      flash[:message] = 'Invalid amount'
      return redirect_to_previous(:controller => 'admin/rcadmin')
    end

    amount = amount.to_f
    months = months.to_i

    customer.add_account_credit(amount, nil, months)
    flash[:message] = "Added #{number_to_currency(amount)} / #{months} months to account credit"
    return redirect_to :back

  rescue
    flash[:message] = 'Error crediting account'
  end
  end

  #----------------------------------------
  # small claims
  #----------------------------------------

  def small_claims_all
    @customers = Customer.candidates_for_smallclaims(1.0) ; nil
  end

  def small_claims
    @customer = Customer.find(params[:id].to_i)
  end

  def credit_customer_account
    
    begin
      customer = Customer.find(params[:customer_id])
      amount = params[:amount].to_f
      months = params[:months].to_i

      # sanity check
      #
      if amount < 0 && ((customer.credit - amount) < 0)
        flash[:message] = "that would bring customer below $0"
        return redirect_to :back
      end

      if months < 0 && ((customer.credit_months - months) < 0)
        flash[:message] = "that would bring customer below 0 months"
        return redirect_to :back
      end

      # do it
      #
      customer.add_account_credit(amount, nil, months)
      flash[:message] = "Added #{number_to_currency(amount)} / #{months} months to account credit"

    rescue
      flash[:message] = 'Error crediting account'

    end

    return redirect_to :back    
    
  end

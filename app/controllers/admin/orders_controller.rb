class Admin::OrdersController < Admin::Base
  def get_class() Order end

  def index
    @orders = []

    fday = params[:fday] || Date.today
    lday = params[:lday] || Date.today

    if (! params[:order_id].nil?)
      @order = Order.find_by_order_id(params[:order_id])
      if  @order.nil?
        flash[:error] = "can't find order #{params[:order_id]}"
      else
        redirect_to :action => :show, :id => @order
        return
      end
    elsif params[:fday]
      if params[:charge_type]
        charge_type = params[:charge_type].to_sym
        @orders = Order.find_by_sql(["select * from orders where orderDate >= ? and orderDate <= ?", fday, lday ])
        @orders = @orders.select { |order| order.match_charge_type(charge_type) }
      elsif params[:source]
        source = @params[:source].to_sym_clean
        @orders = 
        case source
          when :newsletter then Order.via_newsletter(fday, lday, false)
          when :googlead   then Order.via_googlead(fday, lday, false)
          when :affiliate  then Order.via_affiliate(fday, lday, false)
          when :otheronline then Order.via_other_online_ad(fday, lday, false)
          else raise "illegal #{source}"
        end
      else
        raise "unknown spec!"
      end
    elsif (! params[:amount].nil? && ! params[:date].nil?)
      @orders = Order.find_by_sql(["select * from (select co.*, sum(price) as total from orders co, line_items li where co.order_id = li.order_id group by li.order_id) zzz  where total = ? and orderDate = ?", params[:amount], params[:date]]);
    elsif (! params[:amount].nil? &&  params[:date].nil?)
      @orders = Order.find_by_sql(["select * from (select co.*, sum(price) as total from orders co, line_items li where co.order_id = li.order_id group by li.order_id) zzz  where total = ?", params[:amount]]);
    elsif (params[:amount].nil? && !  params[:date].nil?)
      @orders = Order.find_by_sql(["select * from orders where orderDate = ?", params[:date]]);
    end
    
    @total_revenue = @orders.inject(0){ |sum, order| sum+= order.total_price}.to_f
    @total_revenue_after_this_date = @orders.map(&:customer).map(&:orders).flatten.select{ |order| order.orderDate >= fday }.inject(0){ |sum, order| sum+= order.total_price}.to_f
  end

  def show
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @order.to_xml }
    end
  end

  def dispute_chargeback_preview
    @disputed_order = Order.find_by_order_id(params[:id])
    # raise "not an overdue charge" if @disputed_order.server_name != "overdue charge"

    @order_to_items = Hash.new { |hash, key| hash[key] = Array.new }

    @disputed_order.line_items.each do |li|
      parent_li = li.parent_li
      parent_order = parent_li.andand.order
      @order_to_items[parent_order] << parent_li
    end
  end

  def dispute_chargeback_record

    @disputed_order = Order.find_by_order_id(params[:id].to_i)
    dispute = ChargebackDispute.new
    dispute.update_attributes(:order_id => @disputed_order.id,
                              :hr_person_id => params[:person_id])
    flash[:error] = "dispute recorded ; please mail chargeback paperwork ASAP"
    redirect_to :action=>:show, :id => @disputed_order.id
    return
  end

  def new
    @customer = Customer.find(params[:customer_id])
    @products   = ["none", 0] + Product.find(:all, :order => "name" ).map {|x| [ "#{x.name} - #{x.price}", x.id ]  } 
    @order    = Order.new
  end

  def create_it
    begin
      @customer = Customer.find(params["customer_id"].keys.first.to_i)

      products = []
      10.times do | x |
        next if ("none" == params["product#{x}"][:product] )
        products << Product.find(params["product#{x}"][:product].to_i)
      end

      new_order = Order.create_backend_order( @customer, products )
      flash[:notice] = "order #{new_order.id} created"
    rescue
      flash[:error] = "error: #{$!}"
    end
    redirect_to :controller => :customers, :action => :show, :id => @customer.id
  end
  
  def update
    @order = Order.find(params[:id])
    if @order.update_attributes(params[:order])
      flash[:notice] = "Date was successfully updated."
    else
      flash[:error] = "Problem with update"
    end
    redirect_to :action=>:show    , :id => @order
  end

end

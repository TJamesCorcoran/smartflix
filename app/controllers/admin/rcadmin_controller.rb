class Admin::RcadminController < Admin::Base

  # We include this here so that we can use number_to_currency in the flash
  include ActionView::Helpers::NumberHelper

  helper :Rcadmin

  # Present summary of recent orders and recent customers
  def index
    @orders = Order.find(:all, :order => 'order_id DESC', :limit => 20)
    @order_count_today = Order.count(:conditions => 'created_at > curdate()')
    @order_total_today = Order.find(:all, :conditions => 'created_at > curdate()').sum { |o| o.payments.sum(:amount_as_new_revenue) || 0.0 }

    @customers = Customer.find(:all, :order => 'customer_id DESC', :limit => 20)
    @customer_count_full_today = Customer.count(:conditions => 'created_at > curdate() AND shipping_address_id != 0')
    @customer_count_partial_today = Customer.count(:conditions => 'created_at > curdate() AND shipping_address_id = 0')
    @customer_count_orders_today = Customer.count_by_sql("select count(1) from customers, orders where customers.customer_id = orders.customer_id and customers.created_at > curdate()") 
    @one_question_survey = Survey.find(1)
  end

  #----------
  # contests
  #----------
  def contests
    @contests = Contest.all
  end

  def contest
    if params[:id]
      # Updating an existing contest
      @contest = Contest.find(params[:id])
      if request.post?
        @contest.update_attributes(params[:contest])
        flash[:message] = "Updated contest '#{@contest.title}'"
        redirect_to :controller => "admin/rcadmin/contests"
      end
    else
      # Creating a new contest
      @contest = Contest.new
      if request.post?
        @contest = Contest.create(params[:contest])
        flash[:message] = "Created new contest '#{@contest.title}'"
        return redirect_to(:controller => "admin/rcadmin", :action => :contests)
      end
    end
  end

  def contest_phase_increment
    @contest = Contest.find(params[:id])
    @contest.next_phase
    flash[:message] = "Contest '#{@contest.title}' moved to next phase: #{@contest.phase_to_text}"
    redirect_to(:controller => "admin/rcadmin", :action => :contests)
  end



  
  def customers
    @show_origin = true
    @customer_pages, @customers = paginate(:customers,
                                           :per_page => 20,
                                           :order => 'customers.customer_id DESC',
                                           :include => :orders,
                                           :conditions => ["email LIKE ? OR CONCAT(first_name, ' ', last_name) LIKE ?",  #"  <-- that quote fixes emacs color-coding of this file
                                           "%#{params[:q]}%", "%#{params[:q]}%"])
    if (params[:results_only])
      render :partial => 'customer_list', :layout => false
    end
  end

  def customer
    @customer = Customer.find(params[:id])
  rescue
    flash.now[:message] = 'Customer not found'
  end

  def orders
    @order_pages, @orders = paginate(:orders,
                                     :per_page => 20,
                                     :order => 'orders.order_id DESC')
  end

  def order
    @order = Order.find(params[:id])
  rescue
    flash.now[:message] = 'Order not found'
  ensure
    render :template => 'customer/order'
  end

  def coupons

    conditions = []

    conditions << 'code LIKE ?'
    conditions << 'new_customers_only=1' if params[:n] == 'Yes'
    conditions << 'new_customers_only!=1' if params[:n] == 'No'
    conditions << 'single_use_only=1' if params[:s] == 'Yes'
    conditions << 'single_use_only!=1' if params[:s] == 'No'
    conditions << 'active=1' if params[:a] == 'Yes'
    conditions << 'active!=1' if params[:a] == 'No'

    @coupon_pages, @coupons = paginate(:coupons,
                                       :per_page => 15,
                                       :order => 'coupons.coupon_id DESC',
                                       :conditions => [conditions.join(' AND '), "%#{params[:q]}%"])

    # Set up page for toggle_coupon to return to
    flash[:toggle_return] = url_for(params.merge(:results_only => false))

    if (params[:results_only])
      render :partial => 'coupon_list', :layout => false
    end

  end

  def toggle_coupon
    coupon = Coupon.find(params[:id])
    coupon.toggle!(:active)
  ensure
    redirect_to(flash[:toggle_return] ? flash[:toggle_return] : { :action => 'coupons' })
  end

  def create_coupon
    if request.post?
      @coupon = Coupon.new(params[:coupon])
      @coupon_saved = @coupon.save
    end
  end





  # Allow an order to be inserted into the system using a simple web
  # interface that can be accessed by tools like tvr_client; the format
  # for calling it is
  #
  #   insert_order?customer_id=5&order_id=5000&lid[3000]=2000&lid[3001]=3992
  #
  # where oid is the order id and lid is a hash where the keys are the
  # line item IDs and the values are the product IDs. Returns a result
  # page of '1' on success, error message on failure

  def insert_order
    order = Order.for_remote_insert(params[:customer_id], params[:order_id], params[:lid], request.remote_ip)
    payment = Payment.new(:order => order, :customer => order.customer, :payment_method => 'Customer Service',
                          :amount => '0.0', :complete => 1, :successful => 1)
    Order.transaction do
      order.save!
      payment.save!
    end
    render :text => '1'
  rescue => e
    render :text => e.to_s
  end

  # Interface for coupon creation for automated tools
  def insert_coupon
    coupon = Coupon.create!(params[:coupon])
    render :text => coupon.code
  rescue => e
    render :text => "ERROR: #{e.to_s}"
  end


  def promotions
    @promotions = Promotion.find(:all)
  end
  
  def promotion
    if params[:id]
      @promotion = Promotion.find(params[:id])
      if request.post?
        @promotion.update_attributes(params[:promotion])
        if @promotion.errors.size == 0
          redirect_to :action => 'promotions' 
        else
          raise @promotion.errors.full_messages.join('<br>')
        end
        return
      elsif request.delete?
        @promotion.destroy
        redirect_to :action => 'promotions'
      end
    else
      if request.post?
        Promotion.create params[:promotion]
        redirect_to :action => 'promotions'        
      else
        @promotion = Promotion.new
      end
    end
  end
  
  def promotion_pages
    @promotion = Promotion.find(params[:id])
    if request.post?
      reorder_pages params[:order]
      @promotion.promotion_pages.reload
    end
  end
  
  def promotion_page
    @promotion_page = params[:id] ? PromotionPage.find(params[:id]) : PromotionPage.new
    @promotion_id = if params[:id]
      @promotion_page.promotion_id
    else
      params[:promotion_id]
    end
    
    if request.post?
      promotion = Promotion.find(params[:promotion_id])
      order = @promotion_page.order==0 ? promotion.promotion_pages.size + 1 : @promotion_page.order

      @promotion_page.update_attributes params[:promotion_page].update( :promotion_id => promotion.id, :order => order)
      redirect_to :action => :promotion_pages, :id => @promotion_page.promotion.id
    elsif request.delete?
      @promotion_page.destroy
      reorder_pages Promotion.find(@promotion_id).promotion_pages.map{|p| [p.id, p.order]}
      redirect_to :action => :promotion_pages, :id => @promotion_page.promotion.id
    end
  end

  private 
  
  def reorder_pages params
    pages = params.to_a.select{|i| PromotionPage.find(i[0]).order != i[1].to_i} + params.to_a.select{|i| PromotionPage.find(i[0]).order == i[1].to_i}
    pages = pages.sort do |a,b|
      a[1] <=> b[1]
    end
    pages.each_with_index do |page, i|
      PromotionPage.find(page[0]).update_attributes( :order => i+1 )
    end
  end
end

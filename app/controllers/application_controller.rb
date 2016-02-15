class ApplicationController < ActionController::Base

  protect_from_forgery

#  include AbTester
#  acts_as_abtester_application_controller


  # Set up some filters; some notes:
  #
  # When adding a new global filter, ALL filters here should be skipped
  # in the status_controller, and maybe the flipper as well
  #
  # track_origin MUST happen before redirect_clickthroughs (happens automatically with :track_origin_and_redirect)
  # track_first_request MUST happen after redirect_clickthroughs
  #
  #RAILS3  include TrackOrigin
  #RAILS3  include UrlTracker

#  before_filter :track_origin_and_redirect, :setup_customer,  :track_first_request, :track_current_url, :store_browse_history
  before_filter :setup_customer



  helper_method("is_admin?")
  def is_admin?
    @customer && @customer.is_admin?
  end


  private

  # Get the current customer, for use in the wiki plugin
  helper_method :current_customer
  def current_customer
    @customer
  end
  # Another wiki helper, where should we redirect folks for bad requests
  def wiki_default_redirect
    url_for :controller => 'home', :action => ''
  end

  #----------
  # auth tokens (sent via email)
  #----------

  def require_auth_token
    # First see if an auth token has been provided that lets them access
    # the one particular page they are accessing
    @customer = OnepageAuthToken.validate(params[:token],
                                          :controller => controller_name,
                                          :action => action_name,
                                          :id => params[:id])
    return @customer != nil

  end

  def allow_auth_token
    customer = OnepageAuthToken.validate(params[:token],
                                         :controller => controller_name,
                                         :action => action_name,
                                         :id => params[:id])

    # Only set @customer if we FIND a customer.
    # Don't want to trash good work done by other filters if we've got no auth token.
    #
    if customer and @customer.nil?
      @customer = customer 
      session[:customer_id] = @customer.customer_id
      session[:timestamp] = Time.now.to_i
    end
    return true

  end

  def require_full_customer
    @customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil
    require_auth_token if ! @customer

    if @customer.andand.full_customer? 
      return true
    else
      session[:original_uri] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
      redirect_to :controller => 'customer', :action => 'login'
      return false
    end
  end

  # Require login or one-page auth token
  #
  def require_login
    if require_auth_token
      @auth_type = :onepage
      return true
    end

    # Note: There's an odd bug if we just do Customer.find_by_customer_id(session[:customer_id])
    @customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil

    # To allow long term sessions, we don't expire the session, we just
    # expire the authenticated access that the session provides. This
    # allows us to provide customizations and always remember carts, but
    # still time out things like account editing, checkout, etc.
    current_timestamp = Time.now.to_i
    expired = (current_timestamp - session[:timestamp].to_i) >= SmartFlix::Application::SESSION_TIMEOUT
    if (@customer.nil? || expired)
      session[:original_uri] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
      flash[:message] = 
        if @customer.nil?
          "Login is required"
        elsif ! @customer.full_customer? 
          "Please tell us where to send the DVDs!"
        else
          "Your session has timed out, please login again"
        end

      # redirect - normal || AJAX
      if request.xhr?
        session[:original_uri] = nil
        render :update do |page| 
          page.redirect_to( :controller => 'customer', :action => 'login') 
        end
      else
        redirect_to :controller => 'customer', :action => 'login' 
      end

      return false
    end

    session[:timestamp] = current_timestamp

    @auth_type = :login
    return true

  end

  # Require a customer to be present in the session; this is used for
  # lower security auth types where we don't time out the authentication
  def require_customer
    # Note: There's an odd bug if we just do Customer.find_by_customer_id(session[:customer_id])
    @customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil
    unless @customer
      session[:original_uri] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
      flash[:message] = "Please log in to your existing account or sign up for a new account"
      redirect_to :controller => 'customer', :action => 'login'
      return false
    end
    return true
  end

  # Filter that sets up the @customer object based on the session, if we have that data
  def setup_customer
    # Note: There's an odd bug if we just do Customer.find_by_customer_id(session[:customer_id])
    @customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil
    @primary_univ_order = @customer.andand.univ_orders_live.andand.first
  end

  # Filter that stores information on where we've been so that back and
  # cancel buttons always work as expected
  def store_browse_history
    session[:history] ||= []
    # Only store new pages (don't count reloads)
    if (session[:history].last != "#{request.protocol}#{request.host_with_port}#{request.fullpath}")
      session[:history] << "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
      session[:history].slice!(0, [session[:history].size - 2, 0].max) # Keep the most recent two
    end
  end

  # Redirect to the location in browse history, if present, or the default, if not
  def redirect_to_previous(default_url)
    if (session[:history] && session[:history].instance_of?(Array) && session[:history].size > 0)
      redirect_to session[:history][0]
    else
      redirect_to default_url
    end
  end

  # Utility method that redirects after setting a message
  def redirect_with_message(message, redirect_options)
    flash[:message] = message
    redirect_to redirect_options
  end

  # Utility method that renders after setting a message
  def render_with_message(message, render_options)
    flash.now[:message] = message
    render render_options
  end


  # Filter that keeps track of whether this is a visitor's first request
  def track_first_request
    case session[:first_request]
    when nil then session[:first_request] = true
    when true then session[:first_request] = false
    end
    return true
  end

  # Utility method to be called in controllers to determine whether this
  # is a visitor's first request
  def first_request?
    return session[:first_request]
  end


  if Rails.env =="test"
    public
    def zot()                  render :text => 'test'    end  
  end


  # cart checkout, credits
  #
  #
  helper_method :can_use_acct_credit
  def can_use_acct_credit(cart, customer)
    cart.total > 0.0  && customer.credit > 0.0
  end

  helper_method :can_use_univ_month_credits
  def can_use_univ_month_credits(cart, customer)
#    cart.univ_stubs.select{|univ_stub| univ_stub.price > 0 }.any? &&  customer.credit_months > 0
    cart.univ_stubs.any? &&  customer.credit_months > 0
  end

  helper_method :one_univ_month_credit_to_dollars
  def one_univ_month_credit_to_dollars(cart)
    cart.univ_stubs.first.university.subscription_charge_for_n(3)
  end

  def web_only
    raise "only on web" unless SmartFlix::Application::ON_WEB
  end

  def backend_only
    raise "only on web" unless SmartFlix::Application::ON_BACKEND
  end


  #----------
  # univstore stuff
  
  # if a customer has any orders from the current university, and any
  # of their payments were successful, then they are subscribed.
  def already_subscribed?(customer, university)
    customer.orders.any? do |order|
      order.university_id == university.university_id && order.payments.any? { |payment| payment.successful? && payment.complete? }
    end
  end

  # we use this in railscart because a customer might click the upsell button for a univ more than once.
  def already_subscribed_at_all?(customer, university)
    customer.orders.any? do |order|
      order.university_id == university.university_id
    end
  end

  def affiliate_stuff
    # affiliate program
    if session[:affiliate_id]
      begin
        # note that we just associate the affiliate LI with the first LI in the order;
        # this is because of how SFU works; other sites will do things differently
        raise "no first line item; prob a prev univ order exists and this one is empty" if order.line_items.first.nil? && Rails.env == "development"
        affiliate = Customer.find(session[:affiliate_id]).affiliate
        affiliate_log = AffiliateLog.create(:affiliate => affiliate, 
                                            :amount => 20.00,
                                            :note => university.name)
        alli = AffiliateLogLineItem.create(:line_item => order.line_items.first, 
                                           :affiliate_log => affiliate_log)
      rescue Exception  => e
        ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
        # better to lose data than to ever inconvenience the customer!
      end
    else
    end
  end



  def compute_payment_method_str(use_acct_credit,  cc_memo = nil)
    payment_methods = []
    payment_methods << 'Gift Certificate'   if use_acct_credit
    payment_methods << cc_memo  if cc_memo

    payment_methods.join(" / ") 
  end

  # * returns the order
  # * may raise an error
  # * charges credit card (if card does not have decrypted number, charge is deferred for backend)
  #
  # XYZFIX P2: consider doing this inside a 
  #    spawn do 
  #      ...
  #    end
  # block, bc it takes a long time to run
  def charge_and_complete_univ_order(customer, credit_card, university, options = {} )

    options.assert_valid_keys( [ :amount, :how_many_dvds])

    raise "The email address (#{@customer.email}) is already subscribed to #{university.name}; you cannot subscribe more than once."    if already_subscribed?(customer, university)
    raise "No credit card supplied."    if ! credit_card
    
    how_many_dvds = options[:how_many_dvds] || 3

    order = Order.subscribe_to_university_curriculum(university, customer, how_many_dvds)
    order.ip_address = request.remote_ip
    order.server_name = request.host
    order.save!

    # CREATE PAYMENT
    
    amount_total  =  amount_charge = university.first_month_charge

    payment_method_str = compute_payment_method_str( false, credit_card.display_string)

    if (credit_card.number.nil?)

      # this is an F-ed up code flow.  We may be deferring charging,
      # or we may be using a gift cert, or some of both.  If it's JUST
      # a gift cert say that it's complete and good.
      complete_and_successful = ! (amount_charge > 0.00)

      # stored credit card ;  will charge later
      #
      payment = Payment.create(:customer_id => customer.id,
                               :payment_method =>  payment_method_str,
                               :amount => amount_total,
                               :amount_as_new_revenue => amount_charge,
                               :cart_hash => 0,
                               :complete => complete_and_successful,
                               :successful => complete_and_successful,
                               :status => Payment::PAYMENT_STATUS_RECURRING)
      payment.order_id = order.id
      payment.save!
    else
      # live credit card
      #

      begin

        # RAILS3 FaultInject.allow("error in univ cc charge")
        response = ChargeEngine.charge_credit_card(credit_card, 
                                                   amount_charge, 
                                                   order.id,
                                                   "Subscription to #{university.name}.")
        raise response.andand.message if ! response
        payment = Payment.find_by_order_id(order.order_id)
        payment.update_attributes(:amount => amount_total,
                                  :payment_method => payment_method_str )
      rescue Exception => e
        ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
        raise "Error: (#{e}) occurred while trying to charge your credit card; please ensure all your data is correct, and try again, or try a different card."
      end
    end

    host_name = university.university_host_names.andand[0].andand.hostname
    SfMailer.university_welcome(university.name, host_name, customer) 
    affiliate_stuff()

    order
  end


end

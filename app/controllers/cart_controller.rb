require 'money'


class CartController < ApplicationController

  # XXXFIX P3: Do we want some sort of reaper to delete old unchanged carts
  # that aren't associated with customers? That's best with some sort of
  # last updated date

  # List of pages that require a full (not partial) user
  before_filter :require_full_customer, :only => [:checkout]

  # List of pages that require a logged in user
  before_filter :require_login, :only => [:checkout, :claim_code, :postcheckout_show, :order_success]

  # the quick_discount "action" is only used by clickbacks from email
  # sent to users as part of a promotion.
  before_filter :require_auth_token, :only => [:quick_discount]

  # XXXFIX P2: Back button looks like it unmoves the item after a 'save
  # for later' (not really, though), make cart page uncacheable? (make a filter)
  # response.headers['Expires'] = 'Mon, 26 Jul 1997 05:00:00 GMT'
  # response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, post-check=0, pre-check=0'
  # response.headers['Pragma'] = 'no-cache'

  # XXXFIX P2: Somewhere, include 'already rented' (product page? if so, also list 'in cart'?)

  # Display the shopping cart
  def index
    @cart = get_cart()
  end

  # used to be:
  #   trampoline that just slams one ab_test value 
  # now:
  #   test is concluded; deprecated (but keeping the routes alive for a while)
  #
  # REMOVE_AFTER: 1 Jan 2011
  #

  def add_univstub_with_discount()    add_to_cart_common(:add_product, params[:id])  end
  def add_univstub_with_freemonth()    add_to_cart_common(:add_product, params[:id])  end


  # Add a product to the cart
  def add
    add_to_cart_common(:add_product, params[:id])
  end

  def add_saved
    add_to_cart_common(:add_product, params[:id], :save_for_later => true)
  end

  # Add an entire set of products to the cart
  def add_set
    unless params[:id]
      flash[:message] = 'No set specified; please contact info@smartflix.com'
      return redirect_to :back
    end

    add_to_cart_common(:add_set, params[:id])
  end

  def add_saved_set
    add_to_cart_common(:add_set, params[:id], :save_for_later => true)
  end

  # Add a bundle of products to the cart
  def add_bundle
    add_to_cart_common(:add_bundle, params[:id])
  end


  # Add a pair of recommended titles to the cart at the same time!
  def add_pair
    add_to_cart_common(:add_products, [params[:id],params[:second_id]])
  end

  # Delete a product from the cart (on post only)
  def delete
    @product = Kernel.const_get(params[:type].camelize)[params[:id].to_i]


    cart = get_cart()
    cart.delete_product(@product)
  rescue Exception  => e
    flash[:message] = 'Error: Delete from cart operation failed'
    ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
  ensure
    redirect_to(:action => '')
  end

  # Move an item between save for later or buy now part of cart (on post only)
  def move
      cart = get_cart
      cart.toggle_saved_for_later(params[:id])
  rescue Exception  => e
    flash[:message] = 'Error: Could not move item between cart and saved items'
    ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
  ensure
    redirect_to(:action => '')
  end

  private

  def any_univs_in_order(order)
    order.line_items.select {|li| li.product.is_a?(UnivStub)}.any?
  end

  # Convert each unistub line item into its own standalone university order
  #    * remove each univstub from order
  #    * decrement account credit as we use it
  def peel_away_univ_stubs(order, use_acct_credit) 
    uni_orders = []
    order.line_items.select {|li| li.product.is_a?(UnivStub)}.each do |unistub_li|

      uni = unistub_li.product.university
      
      amount_of_regular_credit = use_acct_credit ?
                                 ((unistub_li.product.price < @usable_account_credit)  ?
                                  unistub_li.product.price : @usable_account_credit ) : 0
                                  
      uni_order = charge_and_complete_univ_order(@customer,
                                                 @credit_card,
                                                 uni,
                                                 { :amount => unistub_li.product.price   } )
      order.line_items = order.line_items - [ unistub_li ]
      
      @usable_account_credit -= amount_of_regular_credit
      @customer.subtract_account_credit(amount_of_regular_credit, nil,  0 )
      
      uni_orders << uni_order

      # remove the LI
      unistub_li.destroy
    end
    uni_orders
  end

  def get_empty_payment_object(payment_status, previous_payment, order, payment_method_str, cart_hash, use_stored_cc, amount_to_charge, payment_method = "")
    # Payment status is either immediate or deferred.
    #
    # Note that if the user elects to use account credit AND charge a
    # stored credit card, and the account credit covers the whole
    # purchase, there is no need to create a pending payment, hence
    # the conjunction in the next line:
    
    payment_options = {
      :payment_method => payment_method_str,
      :amount => order.total - @coupon_amount,
      :amount_as_new_revenue => amount_to_charge - @coupon_amount,
      :cart_hash => cart_hash,
      :complete => false,
      # NOTE: not saving the order_id, because we might want to do a swizzle w a uni order
      #       THIS IS IMPORTANT
      # :order => order,
      :successful => false,
      :status => payment_status,
      :payment_method => payment_method_str,
      :message =>"Payment never finalized"
    }
    
    
    # If we have a previous payment (that (we here assume) failed),
    # re-use payment object, otherwise create a new one:
    if (previous_payment)
      payment = previous_payment
      payment.update_attributes(payment_options)
    else
      payment_options[:customer] = @customer
      payment = Payment.create!(payment_options)
    end

    payment
  end

  def get_coupon
    session[:coupon_id] ? Coupon.find_by_coupon_id(session[:coupon_id]) : nil
  end

  def setup_order(postcheckout_sale, request)
    # Set up the (potential) order
    order = Order.for_cart(@cart)
    order.postcheckout_sale = postcheckout_sale
    order.customer = @customer
    order.ip_address = request.remote_ip
    order.server_name = request.host
    
    # Store the short-term origin code in the order if it's set in the session
    if (session[:shortterm_timestamp] && (Time.now.to_i - session[:shortterm_timestamp] < (24 * 60 * 60)))
      order.origin_code = session[:shortterm_origin_code]
    end

    order
  end

  # returns either true or error code
  #
  def setup_cc(use_stored_cc)
    new_cc = nil

    if params[:credit_card].andand[:number]
      params[:credit_card][:number].gsub!(/[^0-9]+/, '') 
      new_cc = CreditCard.secure_setup(params[:credit_card], @customer)
      # why check CC validity here, not outside this branch?  Bc
      # stored cards are invalid - we don't have the plaintext CC #
      return CHECKOUT_CC_INVALID unless new_cc.valid?
    end

    # If the user asked us to use a new CC and they provided a new CC, use it.
    # Else, try to use a stored cc.
    @credit_card =  ( !use_stored_cc && new_cc) || @lastcc

    return CHECKOUT_CC_NONE    if     @credit_card.nil?
    return CHECKOUT_CC_EXPIRED if     @credit_card.andand.expired?
    new_cc.andand.save!
    true
  end

  # on success: nil
  # on error:   [ error_code, details (order) ]
  #
  def setup_cart(force_anon_cart)
    # Get the cart, keeping the anonymous cart if that's what we're working with (don't merge)
    @cart = get_cart(:merge => false, :force_anon_cart => force_anon_cart)

    # Create all the price modifiers that eventually are part of the order and get displayed in the cart
    @price_modifiers = []

    # Coupon? If so, discount is minimum of cart total or coupon amount
    coupon = get_coupon
    @coupon_amount = 0.0
    if (coupon)
      @coupon_amount = [coupon.amount, @cart.total].min
      @price_modifiers << CouponUse.new(:coupon => coupon, :amount => (@coupon_amount * -1.0))
    end

    # MA sales tax -- must be calculate after coupon and discount but before shipping
    if (@customer.shipping_address.state.code == 'MA')
      taxable_sub_total = @cart.taxable_total + @price_modifiers.sum(&:amount)
      @price_modifiers << Tax.new(:amount => ApplicationHelper.round_currency(taxable_sub_total * BigDecimal('0.065')))
    end

    @usable_account_credit = [@cart.total + @price_modifiers.sum(&:amount), @customer.credit].min

    # If the cart is empty either (a) it's just empty, or (b) they just finished an order, but hit reload of this page after it completed
    if (@cart.empty?)
      # See if they just finished an order, but hit reload of this page after it completed
      recent_payment = Payment.find_recent(@customer)
      win = (recent_payment && recent_payment.complete && recent_payment.successful)
      return [ CHECKOUT_SUCCESS, recent_payment.order ] if win
      return [ CHECKOUT_NO_ITEMS, nil ]
    end
    nil
  end

  # on success: nil
  # on error:   error_code
  #
  def check_terms_and_cond(params, options, payment)
    # Make sure they agreed to the terms and conditions; do it here
    # rather than above so the credit card info they typed in is
    # preserved on the page for them (@credit_card is used for that)
    if (!params[:terms_and_conditions] && options[:suppress_terms_and_conds_check].nil?)
      payment.fail!
      return CHECKOUT_TERMS
    end
    nil
  end

  def track_origin_for_checkout(customer)
    coupon = get_coupon
    if (coupon)
      origin = Origin.find_by_customer_id(customer.id)
      if (origin && origin.first_coupon.nil?)
        origin.update_attributes!(:first_coupon => coupon.code)
      end
    end
  end

  def remove_items_from_cart
    # If we're working with an anonymous cart, and the customer
    # also has a permanent cart, remove any items from the
    # permanent cart that the customer just rented. Also, since
    # we're done with the anonymous cart, destroy it.
    if (@customer.cart && @customer.cart != @cart)
      @customer.cart.subtract(@cart)
      @cart.destroy
    else
      # Alternatively, if we're working with the user's personal
      # cart, just empty out the things s/he just purchased.
      @cart.empty_to_buy
    end
    
  end

  def track_ab_results(amount, order)

    # Track all A/B testing results (NOTE: this counts transactions
    # which are deferred, which is incorrect.)

    amount = 100.0 if order.university_id

#    ret = ab_test_result_all_tests(:increment, amount, order)
#    if ret.nil?
#      SfMailer.simple_message(SmartFlix::Application::EMAIL_TO_BUGS, SmartFlix::Application::EMAIL_FROM, "failure with ab_test_result_all_tests" , params.inspect)
#    end
  end

  def deliver_email_confirmation(order)
    # XXXFIX P2: Consider using backgrounDRB
    # Send email to the customer about their purchase and redirect to the success page
    # Create the link URL here, because it's not available in the model
    if order.line_items.any?
      order_url = url_for(:controller => 'customer', :action => 'order', :id => order)
      SfMailer.order_confirmation(order, order_url)
    end
  end

  


  public

  CHECKOUT_NOOP = 1
  CHECKOUT_SUCCESS = 2
  CHECKOUT_NO_ITEMS = 3
  CHECKOUT_DUPLICATE = 4
  CHECKOUT_CC_NONE = 5
  CHECKOUT_CC_EXPIRED = 6
  CHECKOUT_CC_INVALID = 7
  CHECKOUT_CC_FAIL = 8
  CHECKOUT_TERMS = 9
  CHECKOUT_MISC_ERROR = 10

  # Checkout page, collect order information and process it on POST
  # Note: Making changes to this action is tricky! Care required...
  #
  # XXXFIX P3: edit addresses in place on the page using javascript
  # XXXFIX P3: Log some stuff for order placing in production
  #
  # returns [ success, details (i.e. order / error_msg) ]
  #
  def checkout_internal( options = {} )

    options.assert_valid_keys( [ :payment_method,
                                 :force_anon_cart,
                                 :actually_charge_now,
                                 :postcheckout_sale,
                                 :apply_credit,
                                 :suppress_terms_and_conds_check])
    params[:apply_credit]   ||= options[:apply_credit]
    params[:payment_method] ||= options[:payment_method]
    
    # do this early, so that it gets displayed in the 'get' version of the page
    @lastcc =  @customer.find_last_card_used
    @lastcc =  nil if @lastcc.andand.expired?
    
    ret = setup_cart(options[:force_anon_cart])
    return ret if ret
    
    return CHECKOUT_NOOP if !request.post? && ! options[:actually_charge_now]
    
    # Order duplication test: see if there's a payment already in progress
    cart_hash = @cart.cart_hash
    previous_payment = Payment.find_recent(@customer, cart_hash)

    return CHECKOUT_DUPLICATE if (previous_payment && !previous_payment.complete)
    
    # If payment finished, and already succeeded, go to success page.
    # This should never happen, because if the payment was successful
    # then then the cart should be empty; empty the cart just in case.
    if (previous_payment && previous_payment.complete && previous_payment.successful)
      @cart.empty_to_buy
      return [ CHECKOUT_SUCCESS, previous_payment.order]
    end

    
    order = setup_order(options[:postcheckout_sale].to_bool, request)
    
    use_acct_credit  = (params[:apply_credit] && @usable_account_credit > 0.0) 
                       
    use_stored_cc = (params[:payment_method] == "use_last_stored_card") && 
                     (! use_acct_credit || @usable_account_credit < order.total)

    amount_to_charge = use_acct_credit ? (order.total - @usable_account_credit) : order.total

    ret = setup_cc(use_stored_cc)
    return ret if ret != true

    cc_memo = nil
    cc_memo = @credit_card.display_string if amount_to_charge > 0.0

    payment_method_str = compute_payment_method_str(use_acct_credit, cc_memo)

    # Place the order database manipulation in a transaction to preserve atomicity
    payment = nil
    begin

      Order.transaction do
        uni_orders = peel_away_univ_stubs(order, use_acct_credit)
        # univs are removed; recalc amount of account credit
        amount_to_charge = use_acct_credit ? (order.total - @usable_account_credit) : order.total

        payment_status = (!(use_stored_cc && amount_to_charge > 0.0) ? Payment::PAYMENT_STATUS_IMMEDIATE : Payment::PAYMENT_STATUS_DEFERRED)
        payment = get_empty_payment_object(payment_status, previous_payment, order, payment_method_str, cart_hash, use_stored_cc, amount_to_charge, payment_method_str)
        # make sure that the CC is valid
        if !use_stored_cc && (amount_to_charge > 0.0) && ! @credit_card.valid?
          return CHECKOUT_CC_INVALID
        end

        ret = check_terms_and_cond(params, options, payment) 
        return ret if ret

        # Charge the credit card, if it's being used and if the amount is
        # greater than $0 (we collect the data even if the amount is $0.00,
        # just don't charge it in that case).
        if (!use_stored_cc && amount_to_charge > 0.0)

          ret, error_msg = charge_credit_card(@customer, @credit_card, amount_to_charge, payment, @cart.summary)

          if ! ret
            payment.fail!
            payment.update_attributes(:message=> error_msg)
            return [ CHECKOUT_CC_FAIL, error_msg ]
          end
        end

        # As a result of converting unistubs to new orders, this order may now be empty.
        #
        # If empty: do no charging, but overwrite 'order' w the most recent uni order, so that the post-checkout page
        # gets the right variable.
        #
        # If full, process the remaining order items
        #
        if  order.line_items.empty?

          # don't leave an empty order around
          order.destroy
          payment.destroy

          order = uni_orders.first
          payment = order.payments.first
        else
          order.save!

          tie_order_items_to_upsell_recos(order) if params[:postcheckout_sale]
          
          complete_and_successful = (payment_status == Payment::PAYMENT_STATUS_IMMEDIATE)

          payment.update_attributes!(:complete => complete_and_successful,
                                     :successful => complete_and_successful,
                                     :order => order,
                                     :message => "",
                                     :credit_card => @credit_card)
        end
        
        @customer.subtract_account_credit(@usable_account_credit, payment) if (use_acct_credit)
        
        remove_items_from_cart()
        
        begin
          track_origin_for_checkout(@customer)
          # Bc of sort of crappy wart-on-the-side design, we've peeled
          # off uni orders each one has some calculated value (~
          # $100).  If there are more than 1, that matters to AB
          # testing!
          #
          # Either track AB for just this regular order, or for all
          # the uni orders (but avoid aliasing where this stub order
          # might pt to 1 of 2 uni orders...)
          #
          if uni_orders.any?
#            uni_orders.each { |uo| track_ab_results(amount_to_charge, uo) }
          else
#            track_ab_results(amount_to_charge, order)
          end
        rescue Exception  => e
          # don't blow up a checkout for trivial reasons
          ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
        end

      end  # Order.transaction do

    rescue Exception  => e
      payment.fail! if payment
      return CHECKOUT_MISC_ERROR, $!
    end

    # No coupon for next order
    session[:coupon_id] = nil


    # Record the amounts of the payment components
    
    payment.reload
    payment.payment_components << PaymentComponent.new(:payment_method => "account credit", :amount => @usable_account_credit) if use_acct_credit
    payment.payment_components << PaymentComponent.new(:payment_method => cc_memo, :amount => amount_to_charge)       if amount_to_charge > 0.0

    deliver_email_confirmation(order)

    payment.reload
    order.reload

    return [ CHECKOUT_SUCCESS, order ]
  end

  def checkout()
    ret, order = checkout_internal( )
    case ret
      when CHECKOUT_NOOP then     render(:layout => 'layouts/checkout')
      when CHECKOUT_SUCCESS then  
         flash[:order_id] = order.id
         redirect_to(:action => 'order_success', :page => params[:postcheckout_page])
      when CHECKOUT_NO_ITEMS then      redirect_with_message('Error: No items in cart', :action => '')
      when CHECKOUT_DUPLICATE then     render_with_message('Error: Duplicate payment attempt detected, try clicking "place order" again in a few seconds', :layout => 'layouts/checkout')
      when CHECKOUT_CC_NONE then       render_with_message('Error: No valid stored credit card (internal error)', :layout => 'layouts/checkout') 
      when CHECKOUT_CC_EXPIRED then    render_with_message('Error: Credit card expired', :layout => 'layouts/checkout') 
      when CHECKOUT_CC_INVALID then    render_with_message('Error: Invalid credit card', :layout => 'layouts/checkout') 
      when CHECKOUT_CC_FAIL then       render_with_message('Error: credit card charge failed', :layout => 'layouts/checkout') 
      when CHECKOUT_TERMS then         render_with_message('Sorry, you must accept the terms and conditions to rent', :layout => 'layouts/checkout')
      when CHECKOUT_MISC_ERROR then    render_with_message(order, :layout => 'layouts/checkout')
      else raise("unknown checkout status! #{ret} // #{order.inspect}")
    end
  end

  # Allow the user to apply a coupon or gift certificate claim code
  def claim_code

    coupon = Coupon.find_by_code(params[:code])

    if (coupon)

      # Make sure it's 0) a coupon 1) active 2) in date range 3) not
      # previously used by anyone if it's single-use 4) not being used by
      # an old customer if for first-timers-only and 5) not previously
      # used by this customer

      if (!coupon.active? || Date.today < coupon.start_date || Date.today > coupon.end_date)
        # XXXFIX P2: Display coupon errors and successes near coupon? (here and below)
        return redirect_with_message('Error: coupon code is not valid', :action => 'checkout')
      end

      if ((coupon.single_use_only? && coupon.uses.size > 0) || (coupon.used_by?(@customer)))
        return redirect_with_message('Error: this coupon code has already been used', :action => 'checkout')
      end

      if (coupon.new_customers_only? && @customer.orders.size > 0)
        return redirect_with_message('Error: this coupon can only be used by new customers', :action => 'checkout')
      end

      session[:coupon_id] = coupon.id

      return redirect_with_message('Your coupon has successfully been applied!', :action => 'checkout')

    else

      # Not a coupon, see if it's a gift certificate
      gc = GiftCertificate.find_by_code(params[:code])

      if (gc)

        # Make sure the gift certificate has not been used before

        if (gc.used?)
          return redirect_with_message('This gift certificate has already been converted to an account credit, ' +
                                       'see your account credits below', :action => 'checkout')
        end

        @customer.add_account_credit(gc)
        return redirect_with_message('Your gift certificate is now an account credit that will be used for this order, ' +
                                     'see your account credits below', :action => 'checkout')

      else

        return redirect_with_message('Error: no matching coupon or gift certificate code was found', :action => 'checkout')

      end

    end

  end

  # Indicate that the order succeeded
  def order_success
    begin
      @order =  (flash[:order_id] ?   Order.find(flash[:order_id]) : @customer.orders.last)

      flash.keep(:order_id) # Keep the order ID around in case of a reload

      if request.post?
        if params[:customer]
          @order.customer.update_attributes( params[:customer] )
        end
      end

    rescue Exception  => e
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      @order = nil
    end

    @upsell_products = []
    if ! @order.andand.university_id
      @upsell_products = @customer.andand.postcheckout_upsell_recommend(1, 2, @order)
    end
  end

  # The next few functions implement the postcheckout upsell, and the oneclick
  # functions that allow single click upsell.
  #
  # XYZFIX P3: oneclick_checkout_set() and oneclick_checkout() could be rewritten to
  #   not go through the full baroque cart code.
  #

  private

  def tie_order_items_to_upsell_recos(order)
    if order.university
      upo = UpsellOffer.find_all_by_customer_id_and_reco(order.customer.id, order.university).last

      # This is a "should never happen" situation.  Raise in devel environ, else silently do nothing.
      #
      if upo.nil?
        raise "no university upsell found" if Rails.env == "development"
        return
      end
      raise "already subscribed!" if upo.upsell_order_id
      upo.update_attributes(:upsell_order_id => order.id)
    else
      order.line_items.map(&:product).each do |product|

        # we only recommend the first item in a set, not the whole set, so don't complain that
        # set item 2,3,4 wasn't recommended
        next if ! [nil, 1].include?(product.product_set_ordinal)

        upo = UpsellOffer.find_all_by_customer_id_and_reco(order.customer.id, product).last

        # This is a "should never happen" situation.  Raise in devel environ, else silently do nothing.
        #
        if upo.nil?
          raise "no product/set upsell found" if Rails.env = "development"
          return
        end

        raise "already rented!" if upo.upsell_order_id
        upo.update_attributes(:upsell_order_id => order.id)
      end
    end
  end

  def upsell_duplicate?(add_method, id)
    products =
      case add_method
      when :add_product then Array(Video[id])
      when :add_set     then ProductSet[id].andand.products
      else raise "unknown upsell type #{add_methods}"
      end
    (@customer.uncancelled_line_items.map(&:product).to_set.intersection(products.to_set)).empty?.not
  end

  def oneclick_checkout_internal()
    page = params[:postcheckout_page].to_i

    begin
      if upsell_duplicate?(params[:add_function], params[:id].to_i)
        flash[:message] = "Error: You have previously rented one or more of these items"
      else

        add_to_cart_common(params[:add_function],
                           params[:id],
                           :suppress_redirect => true,
                           :create_anon_cart => true)
        @cart = get_cart(:merge => false, :force_anon_cart => params[:force_anon_cart])

        options = {:payment_method => "use_last_stored_card",
                   :actually_charge_now => true,
                   :suppress_terms_and_conds_check => true,
                   :postcheckout_sale => true,
                   :force_anon_cart => true}
        ret, order = checkout_internal(options)

        if order
          page += 1
          flash[:upsell_success] = "You've rented #{order.live_products_as_sentence}!"
        end

      end
    rescue Exception  => e
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      flash[:message] = "error #{$!}!"
    end


    return redirect_to(:action => :postcheckout_show, :page => page)
  end


  public

  def postcheckout_show
    @page = params[:page].to_i
    @order =  (flash[:order_id] ?   Order.find(flash[:order_id]) : @customer.orders.last)

    @final_page = (@page == 4)
    @upsell_products = @page > 4 ? [] : @customer.andand.postcheckout_upsell_recommend(@page, 2 , @order)

    return render(:layout => 'layouts/postcheckout')
  end


  def oneclick_checkout_university()
    university = University.find(params[:id])
    page = params[:postcheckout_page].to_i
    if already_subscribed_at_all?(@customer, university)
      flash[:message] = "you've already subscribed to #{university.name}!"
    else
      order =   charge_and_complete_univ_order(@customer, @customer.find_last_card_used, university)
      order.update_attributes(:postcheckout_sale => true)
      tie_order_items_to_upsell_recos(order)
      page += 1
      flash[:upsell_success] = "You've subscribed to #{university.name}!"
    end
    return redirect_to(:action => :postcheckout_show, :page => page)
  end

  def oneclick_checkout_set()
    params[:add_function] = :add_set
    oneclick_checkout_internal()
  end

  def oneclick_checkout_product()
    params[:add_function] = :add_product
    oneclick_checkout_internal()
  end



  # action invoked via email link with one page auth token; offer discount on selected item
  # params[:token]
  # params[:id]
  def quick_discount

    return redirect_with_message("Error: invalid request.", :action => 'index', :controller => 'store') unless @customer

    cart = Cart.create
    session[:anonymous_cart_id] = cart.id
    cart.add_product( params[:id], :discount => BigDecimal("2.0"))
    newToken = OnepageAuthToken.create_token(@customer, 3, :controller => 'cart', :action => 'checkout')
    redirect_to :action => 'checkout', :token => newToken

  end



  private

  # Retrieve the shopping cart, creating a new one if needed, using the
  # following algorithm
  #
  # 1. If a customer is logged in and has a cart, and there is also an
  # anonymous cart, merge the two carts into the customer's cart and
  # return it (unless the :merge option is false)
  #
  # 2. If a customer is logged in and has a cart, and there is no
  # anonymous cart, return the customer's cart
  #
  # 3. If a customer is logged in and has no cart, but there's an
  # anonymous cart, make the anonymous cart the customer's cart and
  # return it
  #
  # 4. If a customer is logged in and has no cart, and there is no
  # anonymous cart, create a cart for the customer and return it
  #
  # 5. If there is no customer logged in, and there's an anonymous cart,
  # return it
  #
  # 6. If there is no customer logged in, and there's no anonymous cart,
  # create one and return it
  #
  # This function takes one option, :merge, which can be set to false to
  # turn off merging of the "to buy now" portion of the anonymous cart
  # and the customer cart -- this lets someone checkout after a shopping
  # session and not be surprised when something from a previous shopping
  # session tags along (default value is true, and the "save for later"
  # portion of the cart is always merged)
  #
  # Note that the cart is stored in the cart DB table, never in the
  # session, only the ID is stored in the session

  def get_cart(options = {})

    options.assert_valid_keys(:merge, :force_anon_cart)
    options[:merge] = true if options[:merge].nil?

    # XXXFIX P3: WIERD BUG, version 2023, if we just use the finds, sending
    # in nil, sometimes we get a customer! (Is it a caching thing?)

    customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil
    anonymous_cart = session[:anonymous_cart_id] ? Cart.find_by_cart_id(session[:anonymous_cart_id]) : nil

    return anonymous_cart if options[:force_anon_cart]

    if (customer)

      if (anonymous_cart)
        if (customer.cart)
          if (options[:merge])
            customer.cart.merge(anonymous_cart)
            anonymous_cart.destroy
          else
            customer.cart.merge(anonymous_cart, :saved_items_only => true)
            return set_discount(anonymous_cart)
          end
        else
          customer.carts << anonymous_cart
        end
        session[:anonymous_cart_id] = nil
      end

      if customer.carts.empty?
        customer.carts << Cart.create
      end

      return set_discount(customer.cart)

    else

      if (!anonymous_cart)
        anonymous_cart = Cart.create
        session[:anonymous_cart_id] = anonymous_cart.id
      end

      return set_discount(anonymous_cart)

    end
  end

  def set_discount(cart)
    # ABTEST: do we want to reduce the discount on sets?
    cart.global_discount = nil
    cart
  end

  # returns [ success, error_msg = nil ]
  #
  def charge_credit_card(customer, credit_card, amount, payment, summary)

    # Set up the gateway -- test mode is specified in the environment.rb config file
    gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(:login => SmartFlix::Application::AUTHORIZE_NET_API_LOGIN_ID,
                                                               :password => SmartFlix::Application::AUTHORIZE_NET_TRANSACTION_KEY)
    # Set up the credit card authorization options
    options = {
      # We store payment ID as invoice ID - XYZFIX P3 - huh - what is this!?!?!
      :order_id => payment.id, # XYZ P1 - what is this?
      :description => summary,
      :address => {},
      :currency => "USD",
      :billing_address => {
        :name     => customer.full_name,
        :address1 => customer.billing_address.address_1,
        :city     => customer.billing_address.city,
        :state    => customer.billing_address.state.code,
        :country  => customer.billing_address.country.name,
        :zip      => customer.billing_address.postcode
      },
    }

    amount_to_charge = amount * 100.0

    response = gateway.authorize(amount_to_charge, credit_card.active_merchant_cc, options)

    if !response.success?
      return [ false, "Error: There was a problem with your credit card (#{response.message})" ]
    end

    response = gateway.capture(amount_to_charge, response.authorization)

    # In development, this test fails but we want to do it in production
    if (Rails.env == 'production')
      if (!response.success?)
        return [ false, "Error: There was a problem with your credit card (#{response.message})" ]
      end
    end

    return [true, nil ]

  rescue Exception  => e
    ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
    return [ false, "Error: There was a problem with your credit card (#{response.message})" ]
  end

  # Add a single video or a set to cart (on post or pseudo-post only, or with token from email)
  def add_to_cart_common(add_method, arguments, options = {})
    cart_model_options = options.reject { |key,val| [:suppress_redirect,:create_anon_cart].include?(key)}
    
    redirect = { :action => '' }
    
    if params[:token] || options[:create_anon_cart]
      cart = Cart.create
      session[:anonymous_cart_id] = cart.id
      cart.send(add_method, params[:id], cart_model_options)
      redirect = {:action => 'checkout', :token => params[:token]}
    else
      cart = get_cart()
      cart.send(add_method, arguments, cart_model_options)
    end
    
    
  rescue DuplicateItem  => de
    flash[:message] = 'Duplicate item was not added to cart' # + de.inspect
  rescue Exception  => e
    flash[:message] = 'Error: Add to cart operation failed' # + e.inspect
    ExceptionNotifier::Notifier.exception_notification(request.env, e, :data => {:message => "was doing something wrong"}).deliver
  ensure
    redirect_to(redirect) unless options[:suppress_redirect]
  end
end



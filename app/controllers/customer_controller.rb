class CustomerController < ApplicationController

  include UrlTracker


  # List of pages that don't require a logged in user, all others do
  before_filter :require_login, :except => [:login, :new_customer, :logout, :password_reset,
                                            :ajax_hide_firsttimer_box, :ajax_set_emailaddr ]


  # We store information about visitors in several places in the db,
  # even before they register as customers.
  #
  # Once they register as customers (or log in as a pre-existing
  # customer) we want to update these records to point to the
  # customer.
  #
  def util_map_customer(customer, session)
    # url_tracker - hacks table 'url_tracks'
    map_customer_to_session(customer)

    # ab_tester - hacks table 'ab_test_visitors'
#    AbTester.map_customer_to_abtest(customer, session)

    # origin - hacks table 'origins'
    #    note that this duplicates functionality that SHOULD be working in
    #    vendor/plugins/track_origin/lib/track_origin.rb
    #    but seems not to be working
    Origin.map_customer_to_origin(customer, session)
  end

  #----------
  # login / logout
  #----------

  # Display the login page, which also allows new customer signup
  def login

    @supress_left_nav = true

    # Set up the customer and address objects with the customer we failed to save (may be nil)
    @invalid_customer = flash[:invalid_customer]
    @invalid_address = flash[:invalid_address]

    # Set up an email address if the customer is logged in, and make
    # sure it doesn't appear in the new customer fields
    @logged_in_email = @customer ? @customer.email : nil
    @customer = nil if @customer.andand.full_customer?

    if (request.post?)
      customer = Customer.authenticate(params[:email], params[:password])
      if (customer)

        # BEGIN DUPLICATE CODE (also in univstore_controller)
        session[:customer_id] = customer.id
        session[:timestamp] = Time.now.to_i
        # END DUPLICATE CODE

        redirect_uri = session[:original_uri] || session[:ajax_original_uri] || customer_wheres_my_stuff_url
        session[:original_uri] = nil

        util_map_customer(customer, session)

        redirect_to redirect_uri
      else
        flash.now[:message] = "Login failed"
      end
    end

  end

  # Log the current user out
  def logout
    session[:customer_id] = nil
    @customer = nil
    return redirect_to(:controller => :univstore)
  end

  #----------
  # new customer
  #----------

  def ajax_hide_firsttimer_box
    session[:firsttimer_box_hide] = true
    return redirect_to home_url unless request.xhr?
  end

  # front page pop-up: capture email addr of new customer
  #
  def ajax_set_emailaddr
    return redirect_to home_url unless request.xhr?

    password = String.random_alphabetic(8)
    @errors = nil
    @customer = Customer.new(:email => params["email"],
                             :password => password,
                             :password_confirmation => password,
                             :arrived_via_email_capture => 1,
                             :first_ip_addr => request.remote_ip,
                             :first_server_name => request.host)

    session[:firsttimer_box_hide] = true
    if(@customer.save())
      session[:customer_id] = @customer.id
      # ab_test(:funnel_discounts) - no discount was the win
      # discount = 0.0
      # @customer.add_account_credit(discount, "new customer funnel") if discount > 0

      util_map_customer(@customer, session)

      @customer.setup_default_email_preferences(params[:email_notifications] == '1')
      SfMailer.delay.welcome(@customer, password)

      # BEGIN DUPLICATE CODE (also in univstore_controller)
      session[:customer_id] = @customer.id
      session[:timestamp] = Time.now.to_i
      # END DUPLICATE CODE

    else
      @errors = @customer.errors.full_messages.map { |error| error == "Email has already been taken" ? "You've already registered!" : error }
    end

  end
  
  # Add a new customer account
  def new_customer
    return redirect_to(:action => 'login') if !request.post?

    new_customer = Customer.find_by_email(params[:customer][:email])
    if new_customer.nil?
      args = params[:customer].merge({ :first_ip_addr => request.remote_ip,
                                       :first_server_name => request.host})
      new_customer = Customer.new(args)
    elsif ! new_customer.full_customer?()
      new_customer.update_attributes(params[:customer])
    else
      flash[:message] = "Account with that email address already exists.  If you forgot your password, click the 'forgot your password?' link below."
      redirect_to(:action => :login)
      return
    end

    new_customer.first_name = params[:address][:first_name]
    new_customer.first_name = params[:address][:first_name]
    new_customer.last_name = params[:address][:last_name]

    new_customer.setup_default_email_preferences(params[:email_notifications] == '1')

    # We create 2 distinct addresses for shipping and billing, both populated with the same data
    shipping_address = ShippingAddress.new(params[:address])
    billing_address = BillingAddress.new(params[:address])

    # Validate; we want to make sure both are always validated, which
    # doesn't happen if we just || the validations; we assume that the
    # shipping and billing addresses validate the same way

    customer_valid_p = new_customer.valid?
    address_valid_p = shipping_address.valid?

    if (!customer_valid_p || !address_valid_p)

      # Note: Lots of data in the flash here, but not often and never for long, should be ok
      # XXXFIX P4: Is there a railsier way to do this?
      flash[:message] = "Error creating new customer account"
      flash[:invalid_customer] = new_customer
      flash[:invalid_address] = shipping_address
      redirect_to(:action => :login)
      return

    end

    # Everything looks valid, save it
    new_customer.shipping_address = shipping_address
    new_customer.billing_address = billing_address
    new_customer.date_full_customer = Date.today
    new_customer.save!

    # Send the welcome email, wrapped to catch and ignore any errors
    begin
      # XXXFIX P2: Consider using seperate process for sending email (BackgrounDRb)
      SfMailer.welcome(new_customer)
    rescue Net::SMTPFatalError
    end

    # Give them a message
    flash[:message] = "New customer account created"

    util_map_customer(new_customer, session)

    # Log them in right away and redirect
    session[:customer_id] = new_customer.id
    session[:timestamp] = Time.now.to_i
    redirect_uri = session[:original_uri]
    session[:original_uri] = nil
    redirect_to(redirect_uri || { :action => '' })

  end

  #----------
  # edit account info
  #----------

  # Allow name and email address on account to be changed
  # XXXFIX P2: require password re-entry or send email to old and new addresses
  def account_info
    if (request.post?)
      if (@customer.update_attributes(params[:customer]))
        flash[:message] = 'Your account information has successfully been changed!'
      else
        flash.now[:message] = 'Error changing account information'
      end
    end
  end


  # Allow an address to be edited
  def address
    @address = @customer.find_address(params[:id])
    if (request.post?)
      if (@address.nil?)
        flash.now[:message] = 'Error: Could not update address'
      elsif (@address.update_attributes(params[:address]))
        flash[:message] = 'Address successfully updated'
        # Go back to where the session history says we came from, if available
        redirect_to_previous(:action => '')
      end
    else
      if (@address.nil?)
        flash.now[:message] = 'Error: Could not find address'
      end
    end
  end




  # Allow email preferences to be edited
  def email_prefs
    if (request.put?)
      (@customer.update_attributes(params[:customer]))

      # Set up an empty hash if no preferences selected, that may just mean nothing was checked
      new_prefs = (params[:email_preference] && params[:email_preference].is_a?(Hash)) ? params[:email_preference] : {}
      @customer.email_preferences.each do |pref|
        pref.send_email = new_prefs[pref.email_preference_type.form_tag]
        pref.save
      end
      
      flash[:message] = 'Your email preferences have been updated!'
      return redirect_to :back
    end
    @preferences = @customer.email_preferences
  end

  #----------
  # view account info / orders
  #----------

  def index
    if @customer.univ_orders.any? 
      redirect_to :action => 'university_status'    
    else
      redirect_to :action => 'wheres_my_stuff'    
    end
  end


  def wheres_my_stuff
    @crumbtrail = Breadcrumb.for_customer_wheres_my_stuff()

    if (request.put? || request.post?)
      @customer.update_attributes(params[:customer])
      flash[:message] = 'Ship rate successfully updated'
    end
  end

  def university_details
    session[:ajax_original_uri] = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    
    order_id = params[:id]
    @univ_order = Order.find_by_order_id(order_id)

    unless @univ_order.customer == @customer
      flash[:message] = "Order # #{@univ_order.order_id} does not belong to customer # #{@customer_id}" 
      return redirect_to :action => :university_status_all
    end
    
    @crumbtrail = Breadcrumb.for_customer_university_details(@univ_order)
  end

  #========================================
  # queue page
  #========================================

  def university_status_all
    @univ_orders = @customer.univ_orders
  end

  def university_status

    @all = @customer.univ_orders
    params[:id] ||= @all.first.id if @all.size == 1

    return redirect_to :action => :university_status_all unless params[:id]
    @univ_order = Order.find_by_order_id(params[:id].to_i)

    unless @univ_order.andand.customer == @customer
      flash[:message] = "Order # #{@univ_order.andand.order_id} does not belong to customer # #{@customer.id}" 
      return redirect_to :action => :university_status_all
    end

    unless @univ_order.university
      flash[:message] = "Not a university order!" 
      return redirect_to :action => :university_status_all
    end

    @univ_order.normalize_sort_order 

    @crumbtrail = Breadcrumb.for_customer_university_one(@univ_order)
  end

  #========================================
  # univ plan page
  #========================================

  def university_cancel
    @order = Order.find_by_order_id(params["id"].to_i)
    raise "invalid order" unless @order && @order.customer == @customer
    @order.cancel
    flash[:message] = "#{@order.university.name} (order ##{params[:id]}) cancelled; please return all DVDs"
    return redirect_to customer_university_status_all_url
  end

  def change_plan
    @order = Order.find_by_order_id(params[:order_id].to_i) ||
      @customer.univ_orders_live.first

    unless @order
      flash[:message] = "Illegal order" 
      redirect_to :action => :university_status
    end

    unless @order.customer == @customer
      flash[:message] = "Order # #{@order.order_id} does not belong to customer # #{@customer_id}" 
      redirect_to :action => :university_status
    end

    @crumbtrail = Breadcrumb.for_customer_university_plan(@order)
    
    @current_rate = @order.univ_dvd_rate
    @plans = @order.university.plans
  end
  
  def ajax_change_plan

    @order = Order.find_by_order_id(params["order_id"].to_i)
    @num_dvds = params["num_dvds"].to_i
    @error = nil

    if ! @order
      @error = "Illegal order #{params['order_id']}"
    elsif @order.customer != @customer
      @error = "Order # #{@order.order_id} does not belong to customer # #{@customer.customer_id}"
    elsif ! @order.university.plans.keys.include?(@num_dvds)
      @error = "Illegal plan size #{@num_dvds} - choices are #{@order.university.plans.keys.sort.join(',')}"
    end

    return render :ajax_change_plan_error if @error


    @order.set_univ_dvd_rate(@num_dvds)
    @order.save!

    return render :ajax_change_plan

  end


  #========================================
  # univ queue page
  #========================================

  def render_it
    
    li_id         = params[:id].to_i
    @li           = LineItem[li_id]
    @success      = params[:success]
    @product_name = @li.product.name
    @direction    = params[:direction]

    
    if @direction == :cancel
      @verb = "cancelled"
    elsif @direction == :uncancel
      @verb = "uncancelled"
    elsif @direction == :duplicate
      @verb = "re-adding to queue"
    else
      raise "illegal direction"
    end
    
    if @direction == :cancel 
      # change ordinals on all following items 
      @pos = @li.queue_position
      order = @li.order
      order.normalize_sort_order
      order.reload
    end
    
    render :action => 'render_it'
  end


  # move a line item to the top of the queue
  #
  def ajax_univ_move_to_top

    begin
      li_id = params[:id].to_i
      @li = LineItem[li_id]
      raise "invalid line item" unless @li.customer == @customer
      
      @old_position = @li.queue_position

      @modified_lis = @li.move_to_top
    rescue  Exception => e
      @error_str = e.to_s
      render :error
    end
  end

  def ajax_univ_duplicate
    begin
      li_id = params[:id].to_i
      li = LineItem[li_id]

      raise "invalid line item" unless li.customer == @customer

      li.duplicate

      params[:direction] = :duplicate
      render_it()

    rescue  Exception => e
      @error_str = e.to_s
      render :error
    end

  end

  def ajax_univ_cancel_li
    begin
      li_id = params[:id].to_i
      @li = LineItem[li_id]
      raise "invalid line item" unless @li.customer == @customer
      
      #  need to move cancelled items to the cancelled section
      #  also, a nice fading flash would be nice
      #  make sure to test with a session that times out - get redirected to the wrong place
      #  write tests

      unless @li.cancellable?
        @error_str = "#{@li.name} is shipping soon; not cancellable!"
        return render :action => 'error'
      end
      
      @li.cancel
      
      params[:direction] = :cancel
      return render_it()

    rescue  Exception => e
      @error_str = e.to_s
      return render :action => 'error'
    end

  end
  
  def ajax_univ_uncancel_li
    begin
      li_id = params[:id].to_i
      li = LineItem[li_id]
      raise "invalid line item" unless li.customer == @customer
      
      #  also, need to move cancelled items to the cancelled section
      #  also, a nice fading flash would be nice
      #  make sure to test with a session that times out - get redirected to the wrong place
      #  write tests
      
      li.uncancel

      params[:direction] = :uncancel
      render_it()


    rescue  Exception => e
      @error_str = e.to_s
      return render :action => 'error'
    end
  end

  # cut-and-paste programming 
  #     see also app/controllers/admin/customers_controller.rb
  #
  def reinstate_order
    @order = Order.find(params[:id])
    begin
      flash[:error] = "no authority for this action"
      return(redirect_to :action => :show, :id => params[:customer_id] )
    end unless ( @customer == @order.customer)

    @order.andand.reinstate
    flash[:message] = "order #{params[:id]} reinstated"
    redirect_to :action => :university_status
  end






  def recommendations
    @crumbtrail = Breadcrumb.for_store_recommended()

    uni_order = @customer.univ_orders_live.first

    @recommendations = []

    # univ recos
    unless @customer.univ_orders_live.first
        # XYZFIX P2 - we don't want to tell customers who already have a univ to get another
        @recommendations +=  @customer.univs_by_browsed_categories.map(&:univ_stub)  - @customer.univ_order_univs
    end

    # reco engine
    #   we add a reco if either
    #
    #   1) customer is in a uni, and this is a valid thing to add to
    #      that uni (he doesn't already have it in the order, etc.)
    #
    #   2) customer is not in a uni, and therefore we're willing to
    #   take his money!
    #
    @recommendations += @customer.recommended_products.select { |p| p.value == 1}.select { |p| !uni_order || uni_order.andand.can_add_product(p) }


    # tell XYZ is a customer with no recommendations views this page 
    #
    begin
      raise "no recos" if @recommendations.empty?
    rescue Exception => e
    end

    # if a customer views this page and clicks a button, the button
    # should bring him back to this page
    @redirect_to_recos = true
  end

  #----------
  # password changing
  #----------

  # This is where you actually change the password, either via
  #   1) a conventionally logged-in  user, or
  #   2) via a email link w an auth token
  #
  def password_change
    
    if (request.put?)

      # We only require the old password if it's a regular login, not a password reset onepage login
      if (@auth_type == :login)
        reauth_customer = Customer.authenticate(@customer.email, params[:current_password])
        if (!reauth_customer)
          flash.now[:message] = 'Sorry, you did not enter your current password correctly'
          return
        end
      end

      # Note: update_attributes has security problems, since arbitrary
      # items can be changed; we've addressed this by using
      # attr_accessible in the model

      if (@customer.update_attributes(params[:customer]))
        flash[:message] = 'Your password has successfully been changed!'
        # BEGIN DUPLICATE CODE (also in univstore_controller)
        session[:customer_id] = @customer.id
        session[:timestamp] = Time.now.to_i
        # END DUPLICATE CODE

        return redirect_to home_url
      else
        flash.now[:message] = 'Error changing password'
      end
    end
  end

  # Generate a reset-my-password email, which directs to password_change
  #
  def password_reset
    if (request.post?)
      customer = Customer.find_by_email(params[:email])
      if (customer)
        @reset_url = customer_password_change_url(:token => OnepageAuthToken.create_token(customer, 1, :controller => 'customer', :action => 'password_change'))
        SfMailer.reset_password(customer, @reset_url)
      end
    end
  end

  #----------
  # orders
  #----------

  # View the order history
  def order_history
    @orders = @customer.orders
  end

  # View a single order
  def order
    @order = @customer.find_order(params[:id])
    if (@order)
      @crumbtrail = Breadcrumb.for_customer_order(@order)
    else
      flash.now[:message] = 'Error: Could not find order'
      @crumbtrail = Breadcrumb.for_customer_order_history()
    end
  end

  #----------
  # credit cards
  #----------


  def try_card_again
    credit_card = CreditCard.find_by_credit_card_id(params[:card_id].to_i)
    if credit_card.nil?
      flash[:message] = "Credit card not found; please contact customer support"
      return redirect_to( :controller => params[:r_controller],  :action => params[:r_action])
    end
    
    credit_card.incr_extra_attempts
      
    flash[:message] = "Thanks; we'll try your card (#{credit_card.name}) again tomorrow."
    redirect_to :controller => params[:r_controller],  :action => params[:r_action]
  end

  def manage_cc
    # We never actually "update" a credit card - we just let the user clone a CC with a new expiration date.
    # Thus, we might have a given CC in our db multiple times, with newer and newer expiration dates.
    # Hide this from the customer by only showing him the most recent CC for each "series".
    # Of course, if he's got four different CCs (one of them with three expir dates), we want to show him
    # all four different CCs.
    @new_card = CreditCard.new
    
    if (request.post?)

      # We can delete a card via this interface
      if params[:delete]
        cards = @customer.credit_cards.find_all_by_last_four(params[:delete])
        cards.each { |card| card.disabled = true ; card.save(:validate => false) }
        @credit_cards = @customer.reload.credit_cards.select(&:last_four).group_by(&:last_four).map { |key, array| array.max_by { |cc| cc.expire_date} }
        flash[:message] = "Credit card ending in \"#{params[:delete]}\" has been removed" if cards.any?
        return
      end

      # If we're not deleting, we're updating/adding a card

      # this (no radio buttons checked) should never happen, but get all belt-and-suspender on it
      if params[params[:card_choice]].nil?
        flash[:message] =  "Please specify which credit card"
        return
      end
      
      month = params[params[:card_choice]]["month"] 
      year = params[params[:card_choice]]["year"] 
      last_four = params[params[:card_choice]]["last_four"] 
      
      if  "credit_card_new" == params[:card_choice]

        #-----
        # new card
        #-----

        card = CreditCard.secure_setup(params[params[:card_choice]], @customer)
        # this is a hack, but secure_setup isn't doing it!
        card.created_at = card.updated_at = DateTime.now
        success_msg = "Credit card ending in \"#{card.last_four}\" created"
        success = card.save
      else
        #-----
        # update existing card
        #-----
        
        existing_cards = @customer.credit_cards.group_by(&:last_four).map { |key, array| array.sort_by { |cc| cc.expire_date}.last }
        
        cards = existing_cards.select { |cc| cc.last_four == last_four }
        return flash[:message] =  "ERROR: Couldn't find that credit card" if cards.empty?
        
        card = cards.first.clone
        card.month = month
        card.year = year
        
        success_msg = "existing card x#{card.last_four} updated with new expiration date #{month} / #{year}"
        # the credit card calls validate on save, which calls out to the REAL merchant account, and because
        # we don't have the CC number in the clear, that validation will fail.  SO: save w/o validation.

        # this is a hack, but secure_setup isn't doing it!
        card.updated_at = DateTime.now
        success = card.save(:validate => false)

      end

      flash[:message] =  success ? success_msg : card.errors.full_messages.join(",")
    end

    # Load the cards at the end, so that they display any changes we've made
    @credit_cards = @customer.reload.credit_cards.select(&:last_four).group_by(&:last_four).map { |key, array| array.max_by { |cc| cc.expire_date} }

  end
  


  #----------
  # Report a problem with a DVD
  #----------

  # A list of the types that allow reshipment
  #
  ReshipTypes = ['damaged_cracked', 'damaged_not_readable', 'damaged_skips', 
                 'damaged_freezes', 'damaged_sound', 'damaged_other', 'wrong_dvd', 'late']


  # The first thing a user clicks.  This uses AJAX to give them either
  # a form, or an explanation of why they can not report a problem right
  # now.
  #
  def report_problem

    @line_item = @customer.find_line_item(params[:id])
    flash[:message] = 'Error: Could not find item'   unless @line_item

  end

  # Customer got a form w problem choices and submitted it.
  #
  # Give them a 2nd form with further details to fill in.
  #
  def report_problem_2
    @line_item    = @customer.find_line_item(params[:line_item_id])
    @copy         = @line_item.copy
    @problem_type = params[:problem_type]

    valid_problem_types = LineItemProblemType.find(:all).collect { |pt| pt.form_tag } + ['damaged']
    if (params[:problem_type]) || (!valid_problem_types.include?(params[:problem_type]))
      # do something here
    end

    render :report_problem_3 if @problem_type == 'lost_by_customer'

    @partial = "report_problem_#{@problem_type.starts_with?('damaged_') ? 'damaged' : @problem_type}"


  end

  # final step!
  #
  def report_problem_3
    @line_item    = @customer.find_line_item(params[:line_item_id])
    @copy         = @line_item.copy
    @problem_type = params[:problem_type]

    
    # If the form fields have 'final' set, we try to create a problem
    # element for this line item. It will have errors set if any of the
    # data submitted is malformed (ie bad barcode ID for 'wrong_dvd').
    # Reporting a DVD lost does not have a second step, so is
    # automatically final even if final is not set 
    
    flash.now[:message] = "Error: There's a problem in our records - we don't know what copy you have.  Please contact customer support." if @copy.nil?
    
    note = "marked by customer via online interface"
    death_type = nil
    @new_order = act_on_problem(@line_item, @problem_type, params[:wrong_copy_id], params[:reship], request.remote_ip)


  end



  

  # Returns an order if a new order is created
  # Else returns nil
  #
  def act_on_problem(line_item, problem_type_string, wrong_copy_id, reship, ip_address)

    #----------
    # sanity check
    #----------

    # Should only be able to put in one replacement order per item
    return nil if (line_item.children_lis.any?)
    # If the item is not even shipped yet, no deal
    return nil if (!line_item.shipped?)
    # If the item has already been returned, no deal
    return nil if (line_item.returned?)
    # Make sure there's  wrong_copy_id only for wrong copy
    return nil if (wrong_copy_id && problem_type_string != 'wrong_dvd')
    # Reship only if a problem where reship is allowed
    return nil if (reship && !ReshipTypes.include?(problem_type_string))
    # Late only if line item is actually late
    return nil if (problem_type_string == 'late' && !line_item.late?)

    #----------
    # convert user string to DeathType
    #----------

    mark_dead = true

    case problem_type_string
    when 'lostdeath_type'
      death_type = DeathLog::DEATH_LOST_BY_CUST_UNPAID
    when 'damaged_cracked', 'damaged_not_readable', 'damaged_skips',
      'damaged_freezes', 'damaged_sound', 'damaged_other'
      death_type = DeathLog::DEATH_DAMAGED
    when 'late'
      death_type = DeathLog::DEATH_LOST_IN_TRANSIT
    when 'lost_by_customer'
      death_type = DeathLog::DEATH_LOST_IN_TRANSIT
    when 'wrong_dvd'
      if (wrong_copy_id.nil? || wrong_copy_id.strip == "")
        mark_dead = false
        # do nothing
      elsif (@copy.id == wrong_copy_id)
        # We sent the DVD ID we expected, so perhaps the DB is wrong
        note = '[wrong titleID in DB: investigate and fix] ' + note
        death_type = DeathLog::DEATH_DAMAGED
      else
        # We sent the wrong copy, update the right things in the DB
        death_type = DeathLog::DEATH_NOT_DEAD
        @line_item.wrong_copy_sent(Copy.find_by_sticker(wrong_copy_id))
      end
    when 'missing_handout', 'missing_return_label', 'missing_box'
      # Do nothing at DB level for these
      death_type = DeathLog::DEATH_NOT_DEAD
    else
      death_type = DeathLog::DEATH_DAMAGED
      note = "illegal death type specified: #{death_type}; note: #{note}"
    end

    #----------
    # POST CONDITION: we have a death_type and note
    #----------


    #----------
    #  Mark copy dead, create new order
    #----------

    if mark_dead
      @copy.mark_dead(death_type, note)
    end

    # Create the replacement order if needed
    @replacement_order = nil
    if (reship)

      # XXXFIX P2: Consider for_replacement method in Order
      @replacement_order = Order.create!(:orderDate => Date.today, :customer => line_item.order.customer, :ip_address => ip_address)
      @replacement_order.line_items << LineItem.for_product(line_item.product, 0.0, line_item, true, @replacement_order.id)

      # XXXFIX P2: Consider for_replacement method in Payment, and others that set up payment method string (one place all strings!)
      payment = Payment.new(:order => @replacement_order,
                            :customer => @replacement_order.customer,
                            :payment_method => 'Free Replacement',
                            :amount => '0.0',
                            :complete => 1,
                            :successful => 1,
                            :status => 1)

      Order.transaction do
        @replacement_order.save!
        payment.save!
      end
    end

    # Send the emails here, since problem is fully submitted
    # XXXFIX P2: Use BackrounDRb

    SfMailer.problem_report_confirmation(@customer, @line_item, problem_type_string, note, @replacement_order)

    SfMailer.problem_report_to_customer_support(@customer, @line_item, problem_type_string, note, @replacement_order)

    return @replacement_order

  end



end

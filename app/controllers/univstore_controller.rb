class UnivstoreController < ApplicationController

  include UrlTracker

  before_filter :setup_univ
  before_filter :allow_auth_token

  #--------------------
  # setup / teardown funcs
  #--------------------

  

  def setup_univ 

    @univs = []
    if Rails.env == "test"
      @univs = University.find(:all)
    else
      @univs = [5,47,4,1,43,7,48,8,14,3,10,2,41,6,12,61,11,42,74,46].map { |id| University.find(id) }.sort_by(&:name)
    end

    if @customer
      current_univs = @customer.univ_order_univs
      @univs = @univs - current_univs
      if current_univs.map(&:university_id).include?(session[:univ_id].to_i)
        flash[:message] = "You are already subscribed to #{University.find(session[:univ_id]).name}.Perhaps you want to log in to your account (in the upper right hand corner) ?"
        session[:univ_id] = nil 
      end
    end

    @univ_choice = University.find(session[:univ_id]) if session[:univ_id]

  end

  def erase_univ_choice
    
    r_controller = params["src_controller"]
    r_action     = params["src_action"]
    r_id         = params["src_id"]
    
    if request.post?
      session[:univ_id] = nil
      session[:customer_id] = nil
      flash[:message] = "University choice and customer id erased."
    end

    return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )        
  end

  #--------------------
  # pages
  #--------------------


  def index
    session[:how_many_dvds] = 3
  end

  def all
  end

  def one
    # note that 
    #     session[:univ_id] - holds customer choice
    #     @univ             - holds a univ obj built from session[:univ_id]
    # ... but in this case, we want to override @univ based on which page we're viewing
    session[:univ_id] = nil
    @univ = params[:univ_id] && University.find_by_university_id(params[:univ_id]) 
    if @univ.nil?
      return redirect_to(:action => :all )        
    end
    
    
  end

  def how_it_works
  end

  def free_trial_offer
  end

  # 3 cases: either
  #   (a) giving JUST username and password
  #   (b) giving JUST univ
  #   (c) giving both
  def new_signup

    begin 
      r_controller = params["src_controller"]
      r_action     = params["src_action"]
      r_id         = params["src_id"]

      raise "error - no r_controller #{params.inspect}" unless r_controller
      raise "error - no r_action #{params.inspect}"     unless r_action
      
      #----------
      # step 1: customer
      #----------

      if params[:customer] && params[:customer][:email] != ""
        if @customer
          flash[:message] = "Internal error - you're already logged in"
          return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )        
        end
        
        if params["customer"]["email"].nil? || params["customer"]["password"].nil?
          flash[:message] = "Password and Email required."
          return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )        
        end
        
        #         if params["customer"]["email"] != params["customer"]["email_2"]
        #           flash[:message] = "Email addresses don't match."
        #           return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )        
        #         end
        
        #         if params["customer"]["password"] != params["customer"]["password_2"]
        #           flash[:message] = "Passwords don't match."
        #           return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )        
        #         end
        
        #-----
        # login existing or create new customer
        #-----
        
        email = params["customer"]["email"]
        email.gsub!(" ", "")

        if cc = Customer.find_by_email(email) 
          if Customer.authenticate(email, params["customer"]["password"])
            @customer = cc
          else
            flash[:message] = "Customer exists, but incorrect password"
            return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )  if r_id
            return redirect_to(:controller => r_controller, :action => r_action )  
          end
        else
          @customer = Customer.create(:email => email,
                                      :password => params["customer"]["password"],
                                      :password_confirmation => params["customer"]["password_2"],
                                      :arrived_via_email_capture => 1,
                                      :first_ip_addr => request.remote_ip,
                                      :first_server_name => request.host)
          unless @customer.valid?
            raise "Error signing up:  #{@customer.errors.full_messages.join(', ')}"
          end
          @customer.save!
        end    
        # POST-CONDITION: @customer exists

        # BEGIN DUPLICATE CODE (also in customer_controller)
        session[:customer_id] = @customer.id
        session[:timestamp] = Time.now.to_i
        # END DUPLICATE CODE

      end              

      #----------
      # step 2: univ choice (optional)
      #----------
      
      # Customer need not send a university choice
      # ...but if they do, it has to be a valid one, not the "choose one" default.
      #
      
      if params[:university] && params[:university][:university_id] != "0"

        if University.find_by_university_id(params[:university][:university_id].to_i).nil?
          flash[:message] = "You must pick a university."
          return redirect_to(:controller => r_controller, :action => r_action, :id => r_id )  if r_id
          return redirect_to(:controller => r_controller, :action => r_action )  
        else
          session[:univ_id] = params[:university][:university_id] 
        end

      end
      # POST-CONDITION: 
      #    session[:univ_id] is set

      # if we're 100% done with customer && univ choice, move on to step 2, else
      # stay in step 1 to get the rest of the material
      if @customer && session[:univ_id]
        return redirect_to(:action => :set_address )     
      end

      return redirect_to(:controller => r_controller, :action => r_action, :id => r_id ) 
      
    rescue Exception  => e
      flash[:message] = e
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      return redirect_to(:controller => r_controller, :action => r_action, :id => r_id ) 
    end
    
  end

  def pick_how_many_dvds
    return redirect_to(:action => :index) unless @customer && @univ_choice

    if request.post?
      session[:how_many_dvds] = params["how_many"]
      return redirect_to( :action => :set_address)
    end
  end

  def private_addr_do
     params[:address][:country_id] = 223

      @customer.first_name = params[:address][:first_name]
      @customer.last_name = params[:address][:last_name]
      shipping_address = ShippingAddress.new(params[:address])
      billing_address = BillingAddress.new(params[:address])
      
      # Validate; we want to make sure both are always validated, which
      # doesn't happen if we just || the validations; we assume that the
      # shipping and billing addresses validate the same way
      
      customer_valid_p = @customer.valid?
      address_valid_p = shipping_address.valid?
      
      if (!customer_valid_p || !address_valid_p)
        
        # Note: Lots of data in the flash here, but not often and never for long, should be ok
        # XXXFIX P4: Is there a railsier way to do this?
        flash[:message] = "Error creating new customer account"
        flash[:invalid_customer] = @customer
        flash[:invalid_address] = shipping_address
        return redirect_to(:action => :set_address)
        
      end
      
      # Everything looks valid, save it
      @customer.shipping_address = shipping_address
      @customer.billing_address = billing_address
      @customer.date_full_customer = Date.today
      @customer.save!

  end

  def set_address
    return redirect_to(:action => :index) unless @customer && @univ_choice
    return redirect_to(:action => :set_cc) if @customer.billing_address && @customer.shipping_address

#    return redirect_to :action => :pick_how_many_dvds unless session[:how_many_dvds]

    @states  = State.find(:all, :conditions => "state_id <= 65",  :order => "name" ).map {|x| [ x.code, x.state_id ]  } # .map {|x| [ "[#{x.code}] #{x.name}", x.state_id ]  }
    @address = Address.new

    if request.post?
      private_addr_do
      return redirect_to(:action => :set_cc)      
    end
    
  end

  def private_cc_do
      unless params[:terms]
        flash[:message] =  "You must accept the terms to use the service."
        return
      end

      success = false
      begin
        params[:month] = params[:date][:month]
        params[:year] = params[:date][:year]

        card = CreditCard.secure_setup(params, @customer)

        success = card.save
      rescue Exception => e
        flash[:message] =  "CC setup error #{e.message}"
        return
      end

      unless success
        flash[:message] =  success ? success_msg : card.errors.full_messages.join(",")
        return
      end

      begin
        uni_order = charge_and_complete_univ_order(@customer,
                                                   card,
                                                   @univ_choice,
                                                   {}  )
        ab_test_result_all_tests(:increment, 100.0, uni_order)
      rescue Exception => e
        flash[:message] = e.message
        return redirect_to(:action => :set_cc)      
      end

  end

  def set_cc
    return redirect_to(:action => :index)              unless @customer && @univ_choice
    return redirect_to(:action => :set_address)        unless @customer.shipping_address && @customer.billing_address

    @selected_date = Date.today

    if request.post?
      private_cc_do
      return redirect_to(:action => :done)      
    end

  end

  def clear_uni
    session[:univ_id] = nil
	render :update do |page| 
      page.replace_html 'tr_uni_choice_set', render(:partial => 'tr_uni_choice_fluid.html.erb')
	end 
  end

  def done
    # the setup code is going to unset @univ_choice, bc ... we've got a valid order now!
    # ...so we have to reset it here.
    flash[:message]     = nil
    @univ_choice = @customer.univ_orders.last.university
  end

  #----------
  # "come back" email campaign
  #----------

  def welcome_back
    @univ_choice = University.find(params[:univ_id])

    if request.post?

      begin 
        params[:terms] = true # cust already accepted once!

        # find order
        #
        oo = Order.for_cust(@customer).for_univ(@univ_choice.id).last
        raise "error - no #{@univ_choice.name} univ for customer #{@customer.email}!" unless oo
        
        # set cc
        #
        card = CreditCard.secure_setup(params["credit_card"], @customer)
        card_success = card.save
        raise "problem w CC" unless card_success
        
        # set addr
        #
        addr_success = private_addr_do
        raise "problem w addr" unless addr_success

        # test CC
        #
        charge_amount = 0.01
        success, msg = ChargeEngine.charge_credit_card(card, charge_amount, oo.id, "test charge")  
        raise "we tested your credit card and had a problem: #{msg}" unless success
        
        # apply 1 month credit
        #
        @customer.add_account_credit(0, nil, 1)    if @customer.credit_months <= 0

        # reenable univ
        #
        oo.reinstate

        session[:reinstated_univ_id] = oo.id
        return redirect_to :univstore_welcome_back_done, :flash => { :message => "success!" }

      rescue Exception => e

        return redirect_to :back, :flash => { :message => e.message }
      end
    end

  end

  def welcome_back_done
    @reinstated_univ_order = Order[session[:reinstated_univ_id]]
  end


    
  private

  # If a particular URL does not contain the name, redirect to the
  # canonical version of the page (with the name, ie something like
  # video/3726/TIG-Welding-Basics)
  def redirect_to_canonical(item) #  get this working
    name = item.is_a?(Product) ? item.listing_name : item.name
    link_seo_name = ApplicationHelper.link_seo_for(name)
    if (params[:name] != link_seo_name)
      redirect_to params.merge({:name => link_seo_name, :status => 301})
      return true
    end

    return false
  end

end

class StoreController < ApplicationController

  include UrlTracker
#  include AbTester

  def routing_error
    render "index", :status => 404
  end




  # XXXFIX P2: If we want to turn on caching we'll need to 1) fix
  # sort-by bug uses POST on category pages 2) have a different logout
  # strategy (different display depending on whether the user is logged
  # in or not) and 3) wipe cache at every DB push 4) deal with cobranding
  #
  # caches_page :category, :new, :top_rated, :how_it_works, :testimonials, :about_us, :conditions, :privacy

  # List of pages that require a logged in user
  before_filter :require_login, :only => [:review, :redeem, :giftcard, :add_to_queue]

  def throw_exception
    raise "throw_exception"
  end

  def index

    if SmartFlix::Application::UNIV_VIEW_FOR_ALL ||  ! @customer.andand.full_customer? &&
        ( :new_with_indivs == ab_test(:new_univ_funnel, session) ||
         :new_univs_only == ab_test(:new_univ_funnel, session) )
      return redirect_to(:controller => :univstore)
    end
    
    # Set up featured products in each of the featured categories
    # COMPLETED ABTEST: should we show custom featured categories on front page?
    # RESULT: custom_featured_categories are a win, turn them on
    @featured_category_products = {}
    featured_options = @customer ? { :customer => @customer } : {}
    
    # Part of Redesign Optimal.  Win.
    no_of_products = 2
    
    Category.featured(featured_options).each do |cat|
      products = Product.featured(:order => :weighted_random, 
                                  :limit => no_of_products, 
                                  :category => cat,
                                  :include_universities => false)
      if (products.size > 0)
        @featured_category_products[cat] = products
      end
      
      # Limit it to two categories
      break if @featured_category_products.size >= 2
    end
    
    
    # Now get a selection of other featured products that were not chosen above
    @featured_products = Product.featured(:order => :weighted_random,
                                          :limit => 16,
                                          :skip_products => @featured_category_products.values.flatten,
                                          :include_universities => true
                                          )
  end

  def category
    @category = Category.find(params[:id])

    if ! @customer.andand.full_customer? &&
        ( :new_with_indivs == ab_test(:new_univ_funnel, session) ||
          :new_univs_only  == ab_test(:new_univ_funnel, session) )
          
      first_univ = @category.all_universities.first
      # may or may not be a univ for this cat; that's OK.  If not trust univstore to DTRT
      return redirect_to( :controller => :univstore, :action => :one, :id => first_univ.id)
    end

    # If this URL does not have the name, redirect to the proper URL (single canonical page)
    return if redirect_to_canonical(@category)
    @sort_option = ProductSortOption.new(params[:product_sort_option])
    @category_list = Category.display_list(@category)
    @crumbtrail = Breadcrumb.for_category(@category)

    @products = @category.products_for_display

  rescue
    flash[:message] = 'Category not found'
    redirect_to(:controller => 'store')
  end

  def categories
    @categories = Category.find(:all, :conditions => 'parent_id = 0', :order => 'name')
  end

  def popular
    @products = Product.most_popular
  end

  def author
    @author = Author.find(params[:id])
    # If this URL does not have the name, redirect to the proper URL (single canonical page)
    return if redirect_to_canonical(@author)
    @sort_option = ProductSortOption.new(params[:product_sort_option])
    @crumbtrail = Breadcrumb.for_author(@author)
  rescue
    flash[:message] = 'Author not found'
    redirect_to(:controller => 'store')
  end

  def universities
    @univ_stubs = UnivStub.find(:all)
    @crumbtrail = Breadcrumb.for_universities
  end

  def recently_viewed_videos()
    begin
      ids_for_last_n_session_actions(10, "store", "video").map {|product_id| 
        Product.find_by_product_id(product_id)}.reject{|prod| prod.nil? }.uniq
    rescue
      []
    end
  end


  # Display a video
  def video
    @show_right_sidebar = true
    @product = Video.find_by_product_id(params[:id]) || UnivStub.find_by_product_id(params[:id])

    if (:new_univs_only == ab_test(:new_univ_funnel, session) ) && ! @customer.andand.full_customer?

      first_univ = @product.associated_universities.first
      # may or may not be a univ for this cat; that's OK.  If not trust univstore to DTRT
      return redirect_to(:controller => :univstore, :action => :one, :id => first_univ.id) if first_univ

    end

    # If this video is part of a set and not the first element, redirect to the first elememt
    if (@product.product_set_member? && @product.product_set_ordinal != 1)
      redirect_to(:id => @product.product_set.first.id)
      return
    end
    
    # If this URL does not have the name, redirect to the proper URL (single canonical page)
    return if redirect_to_canonical(@product)

    if @product.is_a?(UnivStub)
      uni_id = @product.university_id
      @university = University.find(uni_id, :include => :university_curriculum_elements)
    else
      @recently_viewed_videos = recently_viewed_videos() - [ @product ]
    end
    @category_list = Category.display_list(@product.primary_category)
    @crumbtrail = Breadcrumb.for_category(@product.primary_category)

  rescue
    flash[:message] = 'Video not found'
    redirect_to(:controller => 'store')
  end

  def add_to_queue
    begin
      uni_order = @customer.univ_orders_live.first

      # figure out what to add
      #
      products = []
      if params[:bundle_p] == "true"
        raise "not implemented"
      elsif params[:set_p] == "true"
        products = Product[params[:id].to_i].product_set.products
      else
        products << Product[params[:id].to_i]
      end

      # subtract duplicates
      #
      dup_str = ""
      dup_count = 0
      existing = LineItem.for_order(uni_order).unshipped_active_actionable.map(&:product)
      products.each do |pp|
        if existing.include?(pp)
          products = products - [pp]
          dup_str << "#{pp.name} already in order.  "
          dup_count += 1
        end
      end


      # add it
      #
      products.each do |pp|
        uni_order.univ_add_product(pp)
      end

      msg = "Added #{products.size} items to your queue (#{products.map(&:name).join(',')})"
      msg << "Skipped #{dup_count} items.  " if dup_count > 0
      msg << dup_str
      flash[:message] = msg
    rescue   Exception => e
      flash[:message] = "error!"
      ExceptionNotifier.exception_notification(e)
    end


    controller = params[:r_controller] || 'store'
    action     = params[:r_action] || 'video'
    redirect_to(:controller => controller, :action => action, :id => params[:id])    
  end

  def expand_univ_element
    if request.xhr?
      @video = Video.find(params[:id])
    else
      begin
        return redirect_to :back
      rescue ActionController::RedirectBackError => e
        return redirect_to home_url
      end
    end
  end

  # Display a bundle
  def bundle
    @show_right_sidebar     = true
    @product                = ProductBundle.find(params[:id])
    @crumbtrail             = Breadcrumb.for_category(@product.products.first.primary_category)
    @recently_viewed_videos = ids_for_last_n_session_actions(10, "store", "video").map{|product_id| Product[product_id]}.reject {|prod| prod == @product }.uniq
  rescue
    flash[:message] = 'Bundle not found'
    redirect_to(:controller => 'store')
  end

  # Display the gift certificate purchase page
  def giftcert
    @giftcerts = GiftCert.find(:all)
  end

  # Allow a video to be reviewed (just videos!)
  def review

    @product = Product.find(params[:id])

    # If this product is part of a set and not the first element, redirect to the first elememt
    return redirect_to(:id => @product.product_set.first.id) if (@product.product_set_member? && @product.product_set_ordinal != 1)

    @category_list = Category.display_list(@product.primary_category)
    @crumbtrail = Breadcrumb.for_category(@product.primary_category)
    @new_rating = Rating.new(:rating => 5)

    if (request.post?)
      flash[:message] = ""

      cust_wants_univP = (params[:submit] == "with-univ-sub")
      univ =  University.find_by_university_id(params[:univ_id])
      if cust_wants_univP
        univ_ret = charge_and_complete_univ_order(@customer, @customer.find_last_card_used, univ)
        if univ_ret 
          flash[:message] = "SUCCESS subscribing to #{univ.name}; "
        else
          flash.now[:message] = "ERROR subscribing to #{univ.name}; "
        end
      end


      @new_rating = Rating.new(params[:rating])
      @new_rating.review = nil if @new_rating.review.size == 0
      @new_rating.customer = @customer
      @new_rating.product = @product

      if @new_rating.save
        flash[:message] += "Thanks! The review should appear within one business day."

        if univ && ! cust_wants_univP
          flash[:message] += "Take a look at #{univ.name}."
          redirect_to(:action => univ.univ_stub.action, :id => univ.univ_stub.id, :name => ApplicationHelper.link_seo_for(univ.univ_stub.listing_name))
        else
          redirect_to(:action => @product.action, :id => @product.id, :name => ApplicationHelper.link_seo_for(@product.listing_name))
        end

        return
      else
        flash.now[:message] = flash[:message] + "Error submitting review"
      end
    else

      @univ_upsell = (@product.associated_universities - @customer.univ_orders).first

    end

  rescue
    flash[:message] = 'Error, could not access review page'
    redirect_to(:controller => 'store')
  end

  # XXXFIX P3: Add a simple advanced search page
  # Search functionality
  def search
    query = params[:q]
    if (query)
      query = Riddle.escape(query)

      @matching_products = Video.search(query, 
                   # :conditions => conditions,
                   # :offset => 0,
                   # :limit => offset + RESULTS_PER_PAGE,
                   # :include => inc,
                   # :order => :updated_at, 
                   # :sort_mode => :desc
                   ).to_a

      @matching_categories = Category.search(query, 
                   # :conditions => conditions,
                   # :offset => 0,
                   # :limit => offset + RESULTS_PER_PAGE,
                   # :include => inc,
                   # :order => :updated_at, 
                   # :sort_mode => :desc
                   ).to_a

      @matching_univs = @matching_products.map(&:universities).flatten.sort_by_frequency_with_details[0,2].select {|freq, univ| freq >= 2}.map {|freq, univ| univ }.map(&:univ_stub)

      
    end

  end

  # Display a list of new products, including for RSS and ATOM
  def new
    # XXXFIX P2: Want to have access to new items per category, also with RSS feed
    @new_products = Product.find_new_for_listing()
    options = {
      :feed => {:title => "#{SmartFlix::Application::SITE_NAME} new titles", :link => url_for(:format => nil)},
      :item => {
        :title => :listing_name,
        :pub_date => :date_added,
        :link => lambda { |p| url_for(:action => p.action, :id => p.id) }
      }
    }
  end

  # Display a list of top rated products
  def top_rated
    @top_rated_products = Product.find_top_rated_for_listing()
  end

  # Display a list of recommended products, if we have them for this particular customer
  def recommended
    @recommended_products = @customer.recommended_products
  rescue
    flash[:message] = 'Sorry, no recommended products found, try logging in'
    redirect_to(:controller => 'store')
  end

  # Redirect to wordpress blog
  def smartblog
    headers["Status"] = "301 Moved Permanently"
    redirect_to '/blog'
  end

  def about_us()                end
  def conditions()              end
  def contest_rules()           end
  def giftcard()                end
  def how_it_works()            end
  def image_submission_policy() end
  def press()                   end
  def privacy()                 end
  def testimonials()            end

  # Contact us page
  def contact_us
    # Note: There's an odd bug if we just do Customer.find_by_customer_id(session[:customer_id])
    @customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil
    @message = ContactMessage.new(params[:message])
    @message.ip_address = request.remote_ip
    @message.user_agent = request.user_agent
    if @customer
      @message.name = @customer.full_name if !@message.name || @message.name.size == 0
      @message.email = @customer.email if !@message.email || @message.email.size == 0
      @message.customer = @customer
    end
    if request.post?
      if @message.save
        SfMailer.contact_message(@message)
        SfMailer.contact_message_confirmation(@message)
        
        # XXXFIX P3: Consider seperate page for success to handle customer reload, or other
        @mail_sent = true
      else
        flash.now[:message] = "Error sending message"
      end
    end

  rescue Net::SMTPFatalError

    flash.now[:message] = "Error sending message, did you type in a valid email address?"
    
  end

  # Suggest a video page
  def suggest
    # XXXFIX P3: Lots of duplicate code with above
    # Note: There's an odd bug if we just do Customer.find_by_customer_id(session[:customer_id])
    @customer = session[:customer_id] ? Customer.find_by_customer_id(session[:customer_id]) : nil
    @suggestion = Suggestion.new(params[:suggestion])
    @suggestion.ip_address = request.remote_ip
    if @customer
      @suggestion.name = @customer.full_name if !@suggestion.name || @suggestion.name.size == 0
      @suggestion.email = @customer.email if !@suggestion.email || @suggestion.email.size == 0
      @suggestion.customer = @customer
    end
    if request.post?
      if @suggestion.save
        # XXXFIX P3: Consider also sending email to customer
        SfMailer.suggestion(@suggestion)
        # XXXFIX P3: Consider seperate page for success to handle customer reload, or other
        @mail_sent = true
      else
        flash.now[:message] = "Error sending message"
      end
    end

  rescue Net::SMTPFatalError
    
    flash.now[:message] = "Error sending message, did you type in a valid email address?"
    
  end

  # Redeem a gift certificate
  def redeem
    @univ_stubs = UnivStub.find(:all)

    # Note: we interpret the ID parameter as the gift certificate code
    # rather than its DB ID, perhaps this is improper?

    @gc = params[:id] ? GiftCertificate.find_by_code(params[:id]) : nil

    if @gc

      if (@gc.used?)

        if (@gc.used_by_customer == @customer)
          @gc_state = :used_by_you
        else
          @gc_state = :used_by_someone_else
        end

      else

        @customer.add_account_credit(@gc)
        @gc_state = :credited

      end
          
    else

      flash.now[:message] = "Error, gift certificate code could not be found"
      @gc_state = :not_found

    end

  end

#  def sherline()                  redirect_to :action => 'category', :id => '199', :name => 'Sherline'  end
#  def history()                   redirect_to :controller => 'customer', :action => 'order_history'  end
#  def small_metal_shop()          redirect_to :action => 'category', :id => '283', :name => 'Small Metal Shop'  end
#  def univstub_with_discount()    redirect_to :action => 'video', :id => params[:id]  end
#  def univstub_first_month_free() redirect_to :action => 'video', :id => params[:id]  end

  private

  # If a particular URL does not contain the name, redirect to the
  # canonical version of the page (with the name, ie something like
  # video/3726/TIG-Welding-Basics)
  def redirect_to_canonical(item)
    name = item.is_a?(Product) ? item.listing_name : item.name
    link_seo_name = ApplicationHelper.link_seo_for(name)
    if (params[:name] != link_seo_name)
      redirect_to params.merge({:name => link_seo_name, :status => 301})
      return true
    end

    return false
  end


end

require 'enumerator'


# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  #------------------------------------------------------------
  #
  # Buttons
  #
  #------------------------------------------------------------

  #----------
  # low level: kick out graphics

  # Create an image button
  #
  #  base       - is the base name of the image (ie 'checkout') 
  #
  #  options
  #  :bg      - sets background color (check SCCS file to see what colors are defined!)
  #  :submit  - determines if it's an image submit tag or just an image
  #  :name    - determines the name, submit is used if not specified
  #  :onclick - gets passed to the image
  #  :confirm - gets translated to an onclick that gets passed to the image
  #  :value   - HTML 'value' field 
  #  :big     - bool
   def image_button(base, options = {})
     options.assert_valid_keys(:bg, :submit, :onclick, :name, :value, :big, :confirm)
     options[:bg] ||= :w
     image_options = { }
     image_options[:name] = options[:name] || 'submit'
     image_options[:value] = options[:value]
     # :confirm is not supported for image_submit_tag in 2.0.2
     raise "Cannot use both onclick and confirm" if options[:onclick] && options[:confirm]
     image_options[:onclick] = options[:onclick]
     image_options[:onclick] = "return confirm('#{options[:confirm]}');" if options[:confirm]
     img_file = "buttons/#{base}_#{options[:bg]}#{options[:big] ? '_big' : ''}.jpg" 
     if (options[:submit])
       image_submit_tag(img_file, image_options)
     else
       image_tag(img_file, image_options)
     end
   end


  # Create an appropriate button
  #
  #  base           - text
  #
  #  options
  #    :background  - sets background color
  #    :submit      - determines if it's an image submit tag or just an image
  #    :name        - determines the name, submit is used if not specified
  #    :onclick     - gets passed to the image
  #    :confirm     - gets translated to an onclick that gets passed to the image
  #    :value       - HTML 'value' field 
  #    :big         - bool
  def custom_button(base, options={})
    options[:float]  = :right if options[:product_listing]
    options[:method] ||= :get
    options.delete(:product_listing)


    text = base && base.to_s.titleize.gsub('Dvd','DVD').gsub(/0(\d)/, '\1')
    Button.new(text, options).to_s
  end



  #----------
  # mid level


  def tell_a_friend_button(product)
    return '' unless @customer
    link_to custom_button(:tell_a_friend, { :type => 'grey', :width => 110}),
            { :controller => 'tell_a_friend', :action => 'lightbox', :id => product },
            :class => 'lbOn'
  end

  # Create an appropriate rent button; the base is the base name of the
  # image (ie 'dvd_01', 'now', etc), and options can include :bg, which
  # sets the button background color (valid options are :w and :b), and
  # :image_options, which pass options down to the rails image methods

  def rent_button(base, options)

    options[:type] = %w[set bundle].include?(base) ? :buy : :orange
    options[:width] = %w[bundle].include?(base) ? 105 : 95
    options[:class] = "orange"
    if options[:one_of_set]
      options[:class] = "yellow" 
      options.delete(:one_of_set)
    end

    return custom_button("rent_#{base}", options)
  end

  def buy_gc_button(product_id)

    options = {}
    options[:class] = "orange"
    options[:url] = url_for(:controller => 'cart', :action => 'add', :id => product_id)
    options[:method] = :post
    Button.new(:buy_now, options).to_s

  end

  # 'options' can include
  #   * button_text (overrides default)
  #   * ...
  def univ_sub_button(rental_item, options)
    
    if @customer &&  @customer.already_subscribed?(rental_item.university)
      options[:name] = "submit"
      options[:class] ||= ""
      options[:class] = " dark"
      options.delete(:submit_review)
      text = options[:button_text] || "already_subscribed"
      options.delete(:button_text)
      
      custom_button(text, options)
    else
      options[:name] = "submit"
      options[:size] = " med"
      options[:class] ||= ""
      options[:class] += " orange"
      options.delete(:submit_review)
      text = options[:button_text] || "try_it_risk_free"
      options.delete(:button_text)
      
      custom_button(text, options)
    end
  end

  def save_for_later_button(base, options)
    return custom_button(base,{:type => 'grey'})
  end




  #----------
  # high level


  # Create a button to add a pair of "rent this and that at the same
  # time" products to the shopping cart at the same time.
  def add_pair_to_cart_button_for(this, that, options = {})

    options.assert_valid_keys(:product_listing)

    output = ''
    output << form_tag(:controller => 'cart', :action => :add_pair)
    output << hidden_field_tag('id', this.id)
    output << hidden_field_tag('second_id', that.id)
    output << rent_button("both", options) 
    output << '</form>'

    return output.html_safe
  end


  # Create a single button for a particular product or a full set
  def single_add_to_cart_button_for(rental_item, options = {})

    options.assert_valid_keys(:product_listing, :oneclick_checkout, :postcheckout_page)

    options.delete(:image)    

    options[:confirm] =  "This item is backordered" if (rental_item.respond_to?('backordered?') && rental_item.backordered?) 
    options[:oneclick_checkout] ||= false
    options[:class] = "orange"
    options[:method] = "submit"

    action =
      { Video      => { true => 'oneclick_checkout_product',   false => 'add' },
        ProductBundle => { true => 'oneclick_checkout_product',   false => 'add_bundle' },
        GiftCert   => { true => 'oneclick_checkout_product',   false => 'add' },
        UnivStub   => { true => 'oneclick_checkout_product',   false => 'add' },
        ProductSet => { true => 'oneclick_checkout_set',       false => 'add_set' },
        University => { true => 'oneclick_checkout_university' }} [rental_item.class][options[:oneclick_checkout]]

    options.delete(:oneclick_checkout)
    options.delete(:postcheckout_page)
    options.delete(:submit_review)

    raise "no action for class= #{rental_item.class}, id = #{rental_item.id}, oneclick = #{options[:oneclick_checkout]}" if action.nil?

    # XYZ FIX P3:
    # This is bad OOD.  We want to have a single pass of code here, and push the branching logic down
    # into the three classes.
    #
    button_text = ""
    case rental_item
    when Video 
      if rental_item.product_set_member?
        options[:one_of_set] = true
        button_text = rent_button("dvd_%02d" % rental_item.product_set_ordinal, options)        
      else
        button_text = rent_button("now", options)
      end
    when ProductBundle 
      button_text = rent_button("bundle", options)
    when UnivStub
      button_text << univ_sub_button(rental_item, options)
      return button_text if button_text.match(/already/)
    when GiftCert
      button_text = buy_gc_button(rental_item.id)
    when ProductSet
      button_text = rent_button("set", options)
    when University 
      options.merge( { :type => :orange, :width => "350" })
      button_text = custom_button("Try #{rental_item.name} for one month", options)
    else
      raise "unknown rental_item class #{rental_item.class}"
    end

    output = ''
    output << form_tag(:controller => 'cart', :action => action, :postcheckout_page=> options[:postcheckout_page] )
    output << hidden_field_tag('id', rental_item.id)
    output << button_text
    output << '</form>'
    output.html_safe
  end

  # Create a button to add a product (or move it if already in cart)
  # to the "saved for later"/"wishlist" portion of the shopping cart.
  def add_save_for_later_button_for(product_or_set, options = { })
    options.assert_valid_keys(:product_listing)

    product_p = product_or_set.is_a?(Product)
    set_member_p = product_p ? product_or_set.product_set_member? : false

    output = ''
    
    if (product_p && set_member_p && !options[:product_listing])
      output << form_tag(:controller => 'cart', :action => "add_saved" )
      options[:bg] = :b
      options[:submit] = true
      output << save_for_later_button(:wishlist, options)
    elsif (product_p && !set_member_p)
      output << form_tag(:controller => 'cart', :action => "add_saved" )
      options[:bg] = :b
      options[:submit] = true
      output << save_for_later_button(:wishlist, options)
    else
      output << form_tag(:controller => 'cart', :action => "add_saved_set" )
      options[:bg] = :b
      options[:submit] = true
      output << save_for_later_button(:wishlist, options)
    end

    output << hidden_field_tag('id', product_or_set.id)
    output << '</form>'
    output.html_safe
  end


  #----------
  # ULTRA high level

  # Create buttons used for adding a product to the shopping cart, with
  # multiple buttons for sets

  def display_queue_buttons?()
    @customer.andand.univ_orders_live.andand.any?.to_bool
  end

  def queue_button_for(product, r_controller = nil, r_action = nil)

#    @order = @customer.univ_orders_live.first
    @order = @primary_univ_order

    allowed = true
    allowed = false if product.is_a?(ProductBundle) || ( product.premium? && ! @order.univ_premium?)

    bundle_p = product.is_a?(ProductBundle)
    set_p    = !bundle_p && product.product_set_member?

    output = ""
    if allowed
      output << form_tag(:controller => 'store', :action => "add_to_queue", :id => product.id,
                         :r_controller => r_controller,
                         :r_action => r_action)
      output << hidden_field_tag('bundle_p', bundle_p)
      output << hidden_field_tag('set_p', set_p)
      output << Button.new("add to queue", { :class => :orange, :size => :small_wide, :method =>:submit}).to_s
      output << '</form>'
    else 
      options = {}
      options[:name] = "submit"
      options[:class] = " dark"
      options[:size] = :small

      output << custom_button("premium DVD, not allowed" , options)
    end

    output.html_safe
  end

  def all_add_to_cart_buttons_for(product)
    # set up vars
    #
    output   = ''
    bundle_p = product.is_a?(ProductBundle)
    set_p    = !bundle_p && product.product_set_member?
    products = bundle_p ? product.products : (set_p ? product.product_set.products : [product])

    display_add_set_button_p = set_p && products.detect{|product| product.smart_display?}

    # display the header

    # ab_test(:show_purchase_price_product) - yes, win!
    #
    output << "<div class='purchase_price_comparison_leftshift'>   "
    output << "<div class='purchase_price_comparison'>   "
    output << "<table border='0'><tr>"
    output << "<td class='comparison_right'><strong>list price:</strong></td>"
    output << "<td class='comparison_left'><span class='purchase_price_product'>#{product.comparison_purchase_price.to_f.currency}</span></td>"
    output << "</tr><tr>"
    output << "<td class='comparison_right'><strong>rental:</strong></td>"
    output << "<td class='comparison_left'><span class='rental_price_product'>#{product.comparison_rental_price.to_f.currency}</span></td>"
    output << "</tr><tr>"
    output << "<td class='comparison_right'><strong>you save:</strong></td>"
    output << "<td class='comparison_left'><span class='savings_price_product'>#{product.comparison_savings.to_f.currency}</span></td>"
    output << "</tr><tr>"
    output << "<td class='comparison_right'></td>"
    output << "<td class='comparison_left'>(#{product.comparison_savings_percent}%)</td>"
    output << "</tr></table>"
    output << "</div>"
    output << "</div>"


    # DISPLAY the "add bundle" button (if needed)
    #
    if bundle_p
      output << single_add_to_cart_button_for(product) 
    end

    # DISPLAY the "add set" button (if needed)
    #
    if set_p && display_add_set_button_p
      # Part of Redesign Optimal.  Win.
      output << single_add_to_cart_button_for(product.product_set) + 
        add_save_for_later_button_for(product.product_set) + 
        tell_a_friend_button(product) +
        "<hr />".html_safe
    end

    # DISPLAY the individual buttons
    #
    if !bundle_p
      products.each do |p|
        if (p.smart_display?)
          output << single_add_to_cart_button_for(p)
          output << add_save_for_later_button_for(p) if products.size == 1
          output << tell_a_friend_button(p) if products.size == 1
        else
          output << image_tag('not_available.gif')
        end
        output << "<p><strong>#{p.name}</strong></p>"
      end
    end

      
    output = '<div class="rent-buttons">' + output + '</div>'
      
    return output.html_safe
      
  end

  #------------------------------------------------------------
  #
  # images
  #
  #------------------------------------------------------------

  def image_url_for(product, options = {})
    options.assert_valid_keys(:size, :square)

    case product
    when UnivStub then   product = product.display_product
    when University then product = product.display_product
    end

    if product.product_set_member? 
      product = product.product_set.first
    end

    # construct the image name
    #
    image_name = nil
    if options[:square]
      image_name = "videocap_#{product.id}.jpg"
    else
      prefix = case options[:size]
               when :large then 'l'
               when :small then 's'
               when :tiny then 't'
               when true then 's'
               end
      
      if prefix == 'l'
        image_name = "#{prefix}vidcap_#{product.id}.jpg"
      else
        # use new vidcap style, courtesy of Redesign Optimal
        image_name = "#{prefix}vidcap_#{product.id}_new.jpg"
      end
    end


    # construct the full URL
    #
    if Rails.env == "development"
      return "http://smartflix.com/vidcaps/#{image_name}"
    end

    if (File.file?("#{SmartFlix::Application::VIDCAP_LOCAL_BASE}/#{image_name}"))
      image = "#{SmartFlix::Application::VIDCAP_WEB_BASE}/#{image_name}"
    else
      image = "#{prefix}_image_soon.jpg"
    end

  end

  # Display the image for a product
  def image_for(product, options)
    product = product.display_product if product.is_a?(UnivStub)

    id = options.delete(:id)
    image = image_url_for(product, options)

    alt_text = "#{product.categories.first.andand.name.to_s } how-to video: #{product.listing_name} by #{product.author_name}"

    image_class = case options[:size]
                          when :large then ['vidcap']
                          when :small then ['vidcap-sm']
                          when :tiny then ['vidcap-tn']
                          when true then ['vidcap-sm']
                          end



    return image_tag(image, :alt => alt_text, :title => alt_text, :class => image_class, :id => id)

  end

  def large_image_for(product, id = nil)
    image_for(product, :size => :large, :id => id)
  end

  def small_image_for(product)
    image_for(product, :size => :small)
  end

  def tiny_image_for(product)
    image_for(product, :size => :tiny)
  end

  def square_image_for(product)
    image_for(product, :square => :true)
  end

  def new_banner(product)
    return '' unless product.date_added
    if ab_test(:new_banner, session) == :displayed
      Time.now.months_ago(6) > product.date_added.to_time ? '' : image_tag("new_small.gif", :class => 'new-overlay')
    end
  end

  # Display a rating image (lit bulbs) given a rating as a roundable numeric
  def rating_image(rating, size=:normal)
    nice_rating = rating.andand.round || "nil"
    return image_tag("bulbs/#{nice_rating}_bulb.jpg", :class => 'rating') if size == :large
    image_tag "stars_#{nice_rating.round}.gif"
  end


  #------------------------------------------------------------
  #
  # URLs / links
  #
  #------------------------------------------------------------

  def post_url(post)
    if Rails.env == "development"
      "http://localhost:4000/forums/#{post.topic.forum.id}/topics/#{post.topic.id}/#posts-#{post.id}"
    else
      "http://#{SmartFlix::Application::WEB_SERVER}/forum/forums/#{post.topic.forum.id}/topics/#{post.topic.id}/#posts-#{post.id}"
    end
  end

  def rcadmin_customer_url(id)  
    url_for :controller=> :rcadmin, :action =>:customer, :id => id
  end


  def link_to_or_text(text, options = {})
    if options[:action].andand.to_sym == @action_name.andand.to_sym && 
        (options[:controller].nil? || options[:controller] == params[:controller])
      text
    else
      link_to text, options
    end
  end


  def your_account_link
    name = @customer.andand.display_name_posessive ||  'Your'
    link_to("#{name} Account", :controller => 'customer')
  end


  # Create a link to a product, using it's name as the link text unless
  # given an optional second argument with the link text; we include the
  # product name as part of the link (SEO)

  def link_to_product(product, link_text = nil, ct = nil)
    # We get the action from the product, since it can be video, giftcertificate, etc
    link_to_with_link_text('store', product.action, product.id, product.listing_name, link_text, ct).html_safe
  end

  def tell_a_friend_link()
    return '' unless @customer
    link_to 'Tell a Friend about SmartFlix!', { :controller => 'tell_a_friend', :action => 'lightbox' }, :class => 'lbOn'
  end



  # Create a link to a category, using it's name as the link unless
  # given an optional second argument; we include the category name as
  # part of the link (SEO)

  def link_to_category(category, link_text = nil, ct = nil, css_class=nil)
    css_class = category.selected ? 'selected' : nil
    link_to_with_link_text('store', 'category', category.id, category.name, link_text, ct, css_class)
  end


  # ABTEST
  # Create a link to a category, but also create a menu of its' subcategories
  def link_to_category_with_menu(category, link_text = nil, ct = nil, css_class=nil)
    html = if category.categories.size == 1
             link_to_category(category.categories.first)
           else
             "<a class=\"nolink\">#{category.name}</a>"
           end

    children = category.categories.size == 1 ? category.categories.first.children : category.categories
    unless children.empty?

      # New Menu courtesy of Redesign Optimal.
      html << '<ul class="menu">'

      children.each do |cat|
        html << '<li>'
        html << link_to_category(cat)
        html << '</li>'
      end
      html << '</ul>'
    end

    html
  end

  # Create a link to an author with SEO text

  def link_to_author(author, link_text = nil, ct = nil)
    link_to_with_link_text('store', 'author', author.id, author.name, link_text, ct).html_safe
  end

  def link_to_customer(customer, link_text = nil)
    link_text ||= h(customer.display_name)
    link_to link_text, profile_url(customer)
  end

  #------------------------------------------------------------
  #
  # wiki
  #
  #------------------------------------------------------------


  def self.wiki_page_url_helper(wiki_page)
    wiki_page_url(wiki_page)
  end

  def link_to_create_wiki_article
    if user_is_wiki_editor(current_user) 
      link_to 'create a new article', new_wiki_page_url 
    else
      "#{link_to 'login', :controller => :customer, :action => :login } and then create a new article"
    end
  end


  # Helper methods for use in the wiki plugin
  def wiki_video_link(id)
    video = Product.find_by_product_id(id)
    link_to_product(video) if video
  end

  def wiki_category_link(id)
    category = Category.find_by_category_id(id)
    link_to_category(category) if category
  end

  def wiki_inline(type, id)
    case type
    when /(product|video)/i
      product = Product.find_by_product_id(id)
      output = render(:partial => 'store/new_product_listing_single', :locals => { :product => product }) if product
      output << '<br class="clear"/>' if output
      return output.html_safe
    end
  end
  def wiki_sidebar(type, *args)
    @right_sidebar ||= ''
    @sidebar_type = 'wiki'
    case type
    when /(product|video)/i
      @right_sidebar << wiki_inline(type, args.first).to_s
    when /category/i
      category = Category.find_by_category_id(args.first)
      products = Product.find_top_rated_for_listing(:limit => 5, :category => category) if category
      products.each { |p| @right_sidebar << wiki_inline('product', p.id) } if products
    when /heading/i
      @right_sidebar = "<h2>#{h(args.join(' '))}</h2>\n" + @right_sidebar
    end
    return ''
  end

  #------------------------------------------------------------
  #
  # SEO
  #
  #------------------------------------------------------------

  # Given a name, get the text for that name that should appear in the URL for SEO
  # Note: this is a module method so it can be used in models (ugg?)
  def ApplicationHelper.link_seo_for(name)
    # XXXFIX P4: All these gsubs might be slow, faster way? Is it important? (Profile app)
    name.gsub(/[^a-zA-Z0-9 ]/, '').gsub(/\s+$/, '').gsub(/\s+/, '-')
  end

  # Common code for creating category or product links with the name in
  # the URL

  def link_to_with_link_text(controller, action, id, name, link_text = nil, ct = nil, css_class = nil)
    link_text = h(name) if link_text.nil?
    link_seo = ApplicationHelper.link_seo_for(name)
    # Provide full path only if it's an affiliate link (ct is not nil)
    link_to link_text, {:controller => controller, :action => action, :id => id, :name => link_seo, :ct => ct, :only_path => ct.nil?}, :class => css_class
  end

  #------------------------------------------------------------
  #
  # currency
  #
  #------------------------------------------------------------


  # Given a numerical value, round it to two decimal places
  def ApplicationHelper.round_currency(value)
    (value * 100.0).round / 100.0
  end

  # Given a dollar value to display, display it with the proper
  # formatting, unless it's 0.00, then display nothing
  def number_to_currency_if_positive(number)
    number > 0.0 ? number_to_currency(number) : ''
  end

  #------------------------------------------------------------
  #
  # ???
  #
  #------------------------------------------------------------

  # Get the description that should be listed for a product; for
  # individual products it's just the description, but for sets it might
  # be a single listing or a group of listings with seperate headings;
  # this method yields to a block with each description and (optional)
  # heading and minutes

  def listing_description_for(product)
    if (product.product_set_member? && product.product_set.describe_each_title?)
      product.product_set.products.each { |p| yield p.name, p.description, p.minutes }
    elsif (product.product_set_member?)
      yield nil, product.description, product.product_set.products.inject(0) { |s, p| s + p.minutes } # Simple description, sum minutes
    else
      yield nil, product.description, product.minutes # No heading, simple description, simple minutes
    end
  end



  # Create a hidden field for the onepage auth token if it's set, so
  # that it can be used in post backs
  def onepage_auth_hidden_field
    if (params[:token])
      hidden_field_tag 'token', h(params[:token])
    end
  end


  def preprocess_categories!(category_list)
    selected = category_list.detect { |c| c.selected }
    category_list.each { |c| c.instance_eval { def child_selected?; false end } }
    return if !selected || !selected.parent || selected.toplevel?
    category_list[category_list.index(selected.parent)].instance_eval { def child_selected?; true end }
  end

  # Get an appropriate page title given the current controller and action
  def generate_page_title
    page = "#{params[:controller]}:#{params["action"]}"
    if (page == 'store:video' || page == 'store:review')
      "#{@product.primary_category.name} instruction video: #{@product.listing_name} by #{@product.author_name}"
    elsif (page == 'store:category')
      "#{@category.name} instruction videos on DVD: Learn #{@category.full_path_text(' / ')}"
    elsif (page == 'store:author')
      "Rent videos by #{@author.name} on DVD"
    elsif (page == 'store:new')
      'New video titles at SmartFlix, the Web\'s Biggest How-To DVD Rental Store'
    elsif (page == 'store:top_rated')
      'Top rated video titles at SmartFlix, the Web\'s Biggest How-To DVD Rental Store'
    elsif (page == 'wiki_pages:show')
      "SmartFlix information page: #{h(@wiki_page.name)}"
    elsif (page == 'projects:show')
      "SmartFlix project: #{h(@project.title)}"
    else
      'SmartFlix, the Web\'s Biggest How-To DVD Rental Store'
    end
  end

  # Get appropriate page description given current controller and action
  def generate_page_description
    page = "#{params[:controller]}:#{params[:action]}"
    if (page == 'store:video' || page == 'store:review')
      "Rent #{@product.listing_name} by #{@product.author_name} - DVDs delivered to your door with free shipping!"
    elsif (page == 'store:category')
      "Rent videos on #{@category.name} - DVDs delivered to your door with free shipping!"
    elsif (page == 'store:author')
      "Rent videos by #{@author.name} - DVDs delivered to your door with free shipping!"
    else
      'SmartFlix rents specialty videos on metalworking, painting, woodworking, arts and crafts, ' +
      'vehicle customization, musical instruction, and lots of other trades and hobbies.'
    end
  end

  # Get appropriate page keywords given current controller and action
  def generate_page_keywords
    keywords = %w(rent rental how-to technical instructional video videos dvd dvds SmartFlix)
    keywords << @category.name if @category
    keywords << @author.name if @author
    keywords += Category.find(:all, :conditions => 'parent_id = 0').collect { |c| c.name }
    return h(keywords.join(' '))
  end

  # Generate the tabs at the top of the page
  def generate_tabs

    # in order left-to-right
    tabs = [{:text => "Browse",    :controller=> 'store',       :action => 'index',        :action_match => nil},
            {:text => "Your Queue",      :controller=> 'customer',       :action => 'university_status',        :action_match => 'university_status'},
            {:text => "DVDs you'll love",    :controller=> 'customer',       :action => 'recommendations',        :action_match => 'recommendations'},

            {:text => "How it Works",   :controller=> 'store',       :action => 'how_it_works', :action_match => 'how_it_works'},
            {:text => "Testimonials",   :controller=> 'store',       :action => 'testimonials', :action_match => 'testimonials', },
#            {:text => "Wiki",           :controller=> 'wiki_pages',  :action => 'index',        :action_match => nil},
#            {:text => "Projects",       :controller=> 'projects',    :action => 'index',        :action_match => nil },
#            {:text => "Forum",          :controller=> 'forum',       :action => 'forums',       :action_match => nil},
#            {:text => "Contest",        :controller=> 'contest',     :action => 'show',         :action_match => nil},
#            {:text => "About us",       :controller=> 'store',       :action => 'about_us',     :action_match => 'about_us'}

]

    current = tabs.select { |tab| 
      tab[:controller] == params[:controller] &&
      (tab[:action_match].nil? || tab[:action_match] == params[:action] )
    }.last

    return tabs.collect { |t|
      classes = t == current ? %w[tab active] : %w[tab]
      content_tag(:div, 
        image_tag(t == current ? 'lite_blue_left.jpg' : 'dark_blue_left.jpg', :class => 'left') +
        image_tag(t == current ? 'lite_blue_right.jpg' : 'dark_blue_right.jpg', :class => 'right') +
        link_to(t[:text], { :controller => t[:controller], :action => t[:action], :id => t[:id] }), :class => classes.join(' '))
    }.join("\n").html_safe

  end

  # Common document type
  def doctype
    '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'
  end

  # Given an element, show a spinner and some text that says 'processing' in the element
  def show_waiting(element)
    update_page { |p| p.replace_html(element, '<p>' + image_tag('roller.gif') + ' <strong>Processing</strong></p>') }
  end

  # Determine whether logout link should be shown
  def show_logout
    !session[:customer_id].nil?
  end

  def legacy_stylesheets(type=nil)
    %Q{
    <!--[if IE 6]>
        <link rel="stylesheet" type="text/css" href="/stylesheets/new_ie6.css">
    <![endif]-->
    <!--[if IE 7]>
        <link rel="stylesheet" type="text/css" href="/stylesheets/new_ie7.css">
    <![endif]-->
    }
  end

  def display_survey( id, order_id=nil, partial='shared/survey' )
    return if @customer && @customer.survey_answers.size > 0 && @customer.survey_answers.sort{|a,b| b.created_at <=> a.created_at}[0].created_at > 30.days.ago
    render(:partial => partial, :locals => { :survey => Survey.find(id), :order_id => order_id }).html_safe
  end

  # Given a block of text that might contain text-style paragraphs
  # (multiple linefeeds), insert html paragraphs
  def html_paragraphs(text)
    h(text).split(/\n\s*\n/).collect { |para| "<p>#{para}</p>" }.join("\n")
  end

  def display_author_link(product)
    # Courtesy of Redesign Optimal
    return new_display_author_link(product)
  end

  def new_display_author_link(product)
    link_to_with_link_text('store', 'author', product.author.id, product.author.name, product.author.name, nil).html_safe
  end

  def clickable_contest_thumbnail(photo)
    photo = photo.thumbnails.first if photo.thumbnails.any?
    link_to(image_tag(photo.public_filename), { :controller => 'contest', :action => 'image_lightbox', :id => photo.id }, :class => 'lbOn')
  end

  def project_thumbnail(photo)
    photo = photo.thumbnails.first if photo.thumbnails.any?
    image_tag(photo.public_filename)
  end



  def clickable_project_thumbnail(photo, alt = nil)
    photo = photo.thumbnails.first if photo.thumbnails.any?
    image = image_tag(photo.public_filename, :alt => alt, :title => alt)
    link_to(image, { :controller => 'projects', :action => 'image_lightbox', :id => photo.id }, :class => 'lbOn')
  end

  def project_thumbnail_link_to_project(project)
    photo = project.default_image
    return unless photo
    photo = photo.thumbnails.first if photo.thumbnails.any?
    image = image_tag(photo.public_filename, :alt => project.title, :title => project.title)
    link_to(image, project)
  end

  def current_customer_project(project)
    project.customer == @customer
  end

  # Create a list of objects based on a model, with an optional 0th item
  # denoting 'nothing yet selected', for use in a select; the class must
  # have 'name' and 'id' as valid methods on objects

  def collection_for_select(collection_class, zeroth = false, reverse = false)
    collection = []
    collection << ["Choose a #{collection_class.name}", 0] if (zeroth)
    foo = collection_class.find(:all)
    foo = foo.reverse if reverse
    foo.each { |o| collection << [o.name, o.id] }
    return collection
  end

  # used from admin views to create customer_url
  #
  def url(item)
    case item
      when Video then "fred" 
      else nil
    end
  end
end

module EmailHelper

  #----------
  # buttons 
  #----------  



  # XYZ FIX P3:
  #    it would be nice to have an analogue to
  #    ApplicationHelper::all_add_to_cart_buttons_for()


  #-----
  #   university buttons for email
  #-----

  # 100% off
  def email_freemonth_univ_and_add_to_cart_button( product, options = {})
    stub = nil
    case product
    when UnivStub then   stub = product
    when University then stub = product.univ_stub
    else           raise "illegal class #{product.class}"
    end


    options[:alt_text] = ""

    url = url_for(:host => SmartFlix::Application::WEB_SERVER, 
                  :controller => :cart, 
                  :action => :add_univstub_with_freemonth, 
                  :id => stub.id, 
                  :ct => options[:ct_code], 
                  :_method => 'POST')

    email_univ_sub_button_internal(stub.university.name, url, options)
  end

  # 50% off
  def email_discount_univ_and_add_to_cart_button( product, options = {})
    stub = nil
    case product
    when UnivStub then stub = product
    when Univ then     stub = product.university
    else           raise "illegal class #{product.class}"
    end


    options[:alt_text] = ""

    url = url_for(:host => SmartFlix::Application::WEB_SERVER, 
                  :controller => :cart, 
                  :action => :add_univstub_with_discount, 
                  :id => stub.id, 
                  :ct => options[:ct_code], 
                  :_method => 'POST')

    email_univ_sub_button_internal(stub.university.name, url, options)
  end

  # 0% off

  # takes either univ or univ stub
  #
  def email_univ_sub_button(product, options = {})
    stub = nil
    case product
    when UnivStub then stub = product
    when University then     stub = product.univ_stub
    else           raise "illegal class #{product.class}"
    end
    options[:alt_text] = ""

    url = url_for(:host => SmartFlix::Application::WEB_SERVER, 
                  :controller => :cart, 
                  :action => :add,
                  :id => stub.id, 
                  :ct => options[:ct_code], 
                  :_method => 'POST')

    email_univ_sub_button_internal(stub.university.name, url, options)
  end

  # internal
  private
  def email_univ_sub_button_internal(univ_name, url, options)
    options.assert_valid_keys(:alt_text, :ct_code, :style)

    image_options = Hash.new
    image_options[:alt] = options[:alt_text]
    image_options[:title] = options[:alt_text]
    image_options[:border] = '0'
    image_options[:style] = options[:style] || ""

    ret = link_to image_tag("http://#{SmartFlix::Application::WEB_SERVER}/images/buttons/big_subscribe.jpg", image_options), url
    ret.gsub!(/&amp;/, "&") # UGLY HACK - bc { :escape => false} doesn't work
    ret
  end

  public

  #----------
  # DVDs / sets
  #----------  

  # generate HTML for an img AND a link
  def email_add_to_cart_button(item, token, options = {})

    options.assert_valid_keys(:ctcode, :style)

    options[:style] ||= "margin-top:5px; margin-bottom:40px;"

    product_p = item.is_a?(Video)
    giftcert_p = item.is_a?(GiftCert)
    univ_p = item.is_a?(UnivStub)
    set_member_p = product_p ? item.product_set_member? : false
    
    url = "http://#{SmartFlix::Application::WEB_HOST}/cart/#{ (product_p || univ_p) ? 'add' : 'add_set'}/#{item.id}?token=#{token}"
    url += "&ct=#{options[:ctcode]}" if options[:ctcode]
    options.delete(:ctcode)
    options.delete(:product_listing)

    output = ''
    if giftcert_p
      options[:alt_text] = "Buy a Gift Certificate"
      output << email_rent_button("giftcert", url, options)
    elsif (product_p && set_member_p)
      options[:alt_text] = "Rent DVD #{item.product_set_ordinal} of #{item.listing_name} by #{item.author.name}"
      output << email_rent_button("dvd_%02d" % item.product_set_ordinal, url, options)
    elsif (product_p && !set_member_p)
      options[:alt_text] = "Rent video: #{item.listing_name} by #{item.author.name}"
      output << email_rent_button("now", url, options)
    elsif univ_p
      options[:alt_text] = "Subscribe to #{item.listing_name}"
      output << email_univ_sub_button_internal(item.name, url, options)
    else
      options[:alt_text] = "Rent entire set of #{item.first.listing_name} by #{item.first.author.name}"
      options.delete(:product_listing)
      output << email_rent_button("set", url, options)
    end

    return output

  end


  def email_rent_button(base, url, options)
    options.assert_valid_keys(:alt_text, :ct_code, :style)
    bg = :b
    image_options = Hash.new
    image_options[:alt] = options[:alt_text]
    image_options[:title] = options[:alt_text]
    image_options[:border] = '0'
    image_options[:style] = options[:style] || "margin-top:5px; margin-bottom:40px;"
    ret = link_to image_tag("http://#{SmartFlix::Application::WEB_SERVER}/images/rent_buttons/rent_#{base}_#{bg}.gif", image_options), url
    ret.gsub!(/&amp;/, "&") # UGLY HACK - bc { :escape => false} doesn't work
    ret
  end

  def email_buy_button(url, options)
    options.assert_valid_keys(:alt_text, :ct_code, :style)
    bg = :b
    image_options = Hash.new
    image_options[:alt] = options[:alt_text]
    image_options[:title] = options[:alt_text]
    image_options[:border] = '0'
    image_options[:style] = options[:style] || "margin-top:5px; margin-bottom:40px;"
    ret = link_to image_tag("http://#{SmartFlix::Application::WEB_SERVER}/images/buttons/buy_now_w.jpg", image_options), url
    ret.gsub!(/&amp;/, "&") # UGLY HACK - bc { :escape => false} doesn't work
  end

  #----------
  # URLs 
  #----------  



  def email_url_new_project()
      url_for :only_path => false, :host => SmartFlix::Application::WEB_SERVER, :controller => :projects, :action => :new
  end

  def email_url_for(item, customer=nil)
    case item
    when University 
      return email_url_for(item.univ_stub, customer)
    when Product
      url_for :only_path => false, :host => SmartFlix::Application::WEB_SERVER, :controller => :store, :action => :video, :id => item.id
    when Project
        url_for :only_path => false, :host => SmartFlix::Application::WEB_SERVER, :controller => :projects, :action => :show, :id => item.id
    when WikiPage
        url_for :only_path => false, :host => SmartFlix::Application::WEB_SERVER, :controller => :wiki_pages, :action => :show, :id => item.id
    when Contest
        contest_token = nil
        contest_token = OnepageAuthToken.create_token(customer, 10, :controller => 'contest', :action => 'show', :id => item.id ) if customer
        url_for :only_path => false, :host => SmartFlix::Application::WEB_SERVER, :controller => :contest, :action => :show, :id => item.id, :token => contest_token
    else raise "unknown type"
    end
  end


  #----------
  # giftcard 
  #----------  

  def email_url_for_giftcert
    url_for :only_path => false, :host => SmartFlix::Application::WEB_SERVER, :controller => :store, :action => :giftcert
  end

  #----------
  # images 
  #----------  

  def email_image_url_for_product(products, options)
    options.assert_valid_keys(:size)
    prefix = options[:size] == :large ? 'l' : 's'
    image_name = "#{prefix}vidcap_#{products[0].id}.jpg"

    "http://smartflix.com#{SmartFlix::Application::VIDCAP_WEB_BASE}/#{image_name}"
  end

  def email_image_url_for_project(project, options)
    # XYZFIX P3: sucks
    project.default_image ?
    "http://smartflix.com#{project.default_image.thumbnails.first.public_filename}" : ""
  end

  def email_image_for(item, options = {})
    case item
      when University then
        return email_image_for(item.display_product, options)
      when Product then
        url = email_image_url_for_product(item.product_set_member? ? item.product_set.products : [item], options)
        alt_text = "#{item.listing_name} by #{item.author.name}"
      when Project then
        url = email_image_url_for_project(item, options)
        alt_text = "#{item.title} by #{item.customer.display_name}"
      else raise "unknown type"
    end

    return image_tag(url, :alt => alt_text, :title => alt_text, :border => '0')
  end

  def email_small_image_for(item)
    email_image_for(item, :size => :small)
  end

  def email_large_image_for(item)
    email_image_for(item, :size => :large)
  end


end

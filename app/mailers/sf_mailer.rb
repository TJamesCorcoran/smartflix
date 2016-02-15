class SfMailer < ActionMailer::Base

  helper :email

  #========================================
  #   generic
  #========================================

  def simple_message(to, from, subject, message)
    message += "\n---------\n DEVEL MODE: sent to #{SmartFlix::Application::EMAIL_TO_DEVELOPER} instead of #{to}" unless        Rails.env == 'production' 
    @message = message
    
    mail(subject:    subject,
         to:                Rails.env == 'production' ? to : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       from,
         message:   message
         ).deliver
  end

  #========================================
  #   base SmartFlix stuff
  #========================================


  # Send welcome email
  def welcome(customer, password = nil)
    @customer = customer
    @password = password
    mail(subject:    "Welcome to #{SmartFlix::Application::SITE_NAME}",
         to:        Rails.env == 'production' ? customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send order confirmation email
  def order_confirmation(order, url)
    @order = order
    @url = url
    mail(subject:    "#{SmartFlix::Application::SITE_NAME} Order Confirmation (Order ##{order.id})",
         to:        Rails.env == 'production' ? order.customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send reset password email
  def reset_password(customer, url)
    @customer = customer
    @url = url
    mail(subject:    "#{SmartFlix::Application::SITE_NAME} password reset requested",
         to:        Rails.env == 'production' ? customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send customer problem report confirmation email
  def problem_report_confirmation(customer, line_item, death_type, note, replacement_order)
    @customer = customer
    @line_item = line_item
    @death_type = death_type
    @note = note
    @replacement_order = replacement_order
    mail(subject:    "Problem report received by #{SmartFlix::Application::SITE_NAME}",
         to:        Rails.env == 'production' ? customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send email about customer problem report to customer support
  def problem_report_to_customer_support(customer, line_item ,death_type, note, replacement_order)
    @customer = customer
    @line_item = line_item
    @death_type = death_type
    @note = note
    @replacement_order = replacement_order
    mail(subject:    "CUSTOMER GATEWAY",
         to:        Rails.env == 'production' ? SmartFlix::Application::EMAIL_FROM_SUPPORT : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       customer.email).deliver
  end

  def contact_message(message)
    @message = message
    mail(subject:    "#{SmartFlix::Application::SITE_NAME} Customer Support",
         to:        Rails.env == 'production' ? SmartFlix::Application::EMAIL_FROM_SUPPORT : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       message.email).deliver
  end

  def contact_message_confirmation( message)
    @message = message
    mail(subject:    "#{SmartFlix::Application::SITE_NAME} Customer Support: Received",
         to:        Rails.env == 'production' ? message.email : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  def suggestion(suggestion)
    @suggestion = suggestion
    mail(subject:    "#{SmartFlix::Application::SITE_NAME} Customer Suggestion",
         to:        Rails.env == 'production' ? SmartFlix::Application::EMAIL_TO_PURCHASING : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       suggestion.email).deliver
  end

  # Send tell-a-friend email
  def tell_a_friend(recipient, customer, message, product, clickthrough_id)
    @customer = customer
    @message = message
    @product = product
    @ct_code = "taf#{clickthrough_id}"
    mail(subject:    product ? "#{customer.full_name} thinks you'll be interested in this video" : "#{customer.full_name} thinks you'll be interested in SmartFlix.com",
         to:        Rails.env == 'production' ? recipient : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       customer.email).deliver
  end

  def weekly_charge( args )
    args.assert_valid_keys( :customer, :copies, :credit_card, :weekly_rate, :price, :last_four, :in_last_chargeable_month )
    @customer = args[:customer]
    @copies = args[:copies]
    @credit_card = args[:credit_card]
    @weekly_rate = args[:weekly_rate]
    @price = args[:price]
    @last_four = args[:last_four]
    @in_last_chargeable_month = args[:in_last_chargeable_month]
    
    @args = args
    mail(subject:     'SmartFlix: weekly charge for videos',
         to:         Rails.env == 'production' ?  args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  # Send message regarding charging for overdue videos
  # Send message regarding charging for videos reported lost by the customer
  def lost_charge( args )
    args.assert_valid_keys( :customer, :copies, :last_four, :sum_price, :because_cc_expiring )
    @customer = args[:customer]
    @copies = args[:copies]
    @last_four = args[:last_four]
    @sum_price = args[:sum_price]
    @because_cc_expiring = args[:because_cc_expiring]
    
    @args = args
    mail(subject:     'SmartFlix: charge for lost videos',
         to:         Rails.env == 'production' ?  args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM).deliver
  end
  
  # Send a message about a shipment to a customer
  def shipment_email(to, customer, shipment, titles, unfulfilled_titles)
    @customer = customer
    @shipment = shipment
    @titles = titles
    @unfulfilled_titles = unfulfilled_titles
    mail(subject:    "SmartFlix.com DVD Order Status",
         to:        Rails.env == 'production' ? to : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send a message about an order that is OOS to a customer
  def oos_email(to, customer, unfulfilled_titles)
    @customer = customer
    @unfulfilled_titles = unfulfilled_titles
    mail(subject:    "SmartFlix.com DVD Order Status",
         to:        Rails.env == 'production' ? to : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send a message about returned videos
  def solicit_univ_reviews(customer, univstub, review_url)
    @customer = customer
    @univstub = univstub
    @review_url = review_url
    mail(subject:    "Please review '#{univstub.name}'",
         to:        Rails.env == 'production' ?   customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  # Send a message about returned videos
  def return_email(to, title, review_url)
    @title = title
    @review_url = review_url
    mail(subject:    "SmartFlix received '#{title}'",
         to:        Rails.env == 'production' ?   to : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end
  
  
  # Send messages for Abandoned Basket Emails ( lib/tvr/do.rb )
  #
  # Why use real recipients for test environment?  Bc otherwise, in
  # test code, EVERY email seems to go to the developer, and you can't
  # see if the code is working...
  #
  def abandoned_basket(customer, cart)
    @customer = customer
    @cart = cart
    mail(subject:     "Your SmartFlix.com Shopping Cart",
         to:         Rails.env == 'production' ||        Rails.env == 'test'  ?   customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM).deliver
  end

  #----------
  # marketing emails
  #----------
  
  # Send messages recommending particular titles
  def recommendation( args )
    args.assert_valid_keys( :customer, :products, :type, :token )
    @customer = args[:customer]
    @products = args[:products]
    @type = args[:type]
    @token = args[:token]
    
    @args = args

    ab_hh = {}
    ab_subj = ab_test(:univreco_mail_subject, ab_hh)
    
    mail(subject:     args[:type] == 'new' ? %Q{Smartflix has new Titles, like "#{args[:products][0].name}"} : %Q{Smartflix recommends "#{args[:products][0].name}"},
         to:         Rails.env == 'production' ? args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM).deliver
    
  end

  # recruit new univ customers
  def univ_new_cust(customer, univ)
    
    fake_session = {:is_robot => false}

    #-----
    # subject line

    coupon_size = "$#{University.first.subscription_charge.ceil.to_i}"

    ab_subj = ab_test(:univreco_mail_subject, fake_session)
    
    @subj = case ab_subj
           when :brand_and_price then       "[ SmartFlix ] #{coupon_size} coupon"
           when :one_month_free then        "One month free trial offer on how-to DVDs"
           when :come_back then             "Come back to SmartFlix - your first month is free"
           when :newsletter_coupon then     "SmartFlix newsletter (contains #{coupon_size} coupon)"
           when :newsletter_expiration then "SmartFlix newsletter (#{coupon_size} coupon expires in 3 days)"
           when :univ_name_q then           "Want to learn about #{univ.name_verb.downcase}?"
           when :univ_name then             "Learn about #{univ.name_verb.downcase}"
           when :univ_name_q_sf then        "Smartflix: want to learn about #{univ.name_verb.downcase}?"
           when :univ_name_sf then          "Learn about #{univ.name_verb.downcase} at Smartflix"
           else raise "error - unknown '#{ab_subj}'"
           end

    #-----
    # email body

    @ab_body = ab_test(:univreco_mail_body, fake_session)

    #-----
    # send email
    
    @customer = customer
    @univ     = univ
    @abtvid   = fake_session[:ab_test_visitor_id]
    @token    = OnepageAuthToken.create_token(customer, 7, { :controller => '*', :action => '*'})

    mail(subject:     @subj,
         to:          Rails.env.production?  ? customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM).deliver
    
  end

  def univ_old_cust(customer, univ)
    
    # universal login token
    login_token = OnepageAuthToken.create_token(customer, 
                                                7, 
                                                { :controller => '*', :action => '*'})
    
    # A/B test: which univreco subject, body 
    fake_session = {:is_robot => false}
    ab_subj      = ab_test(:univ_comeback_mail_subject, fake_session)
    ab_body      = ab_test(:univ_comeback_mail_body, fake_session)
    abtvid       = fake_session[:ab_test_visitor_id]
    
    
    puts "   * univ = #{univ.id} / #{univ.name}"
    puts "   * ab_subj = #{ab_subj}"
    puts "   * ab_body = #{ab_body}"
    puts "   * abtvid  = #{abtvid}"
    
    coupon_size = "$#{University.first.subscription_charge.ceil.to_i}"
    
    subj = case ab_subj
           when :brand_and_price then       "[ SmartFlix ] #{coupon_size} coupon"
           when :newsletter_expiration then "SmartFlix newsletter (#{coupon_size} coupon expires in 3 days)"
           when :newsletter_coupon then     "SmartFlix newsletter (contains #{coupon_size} coupon)"
           else raise "error - unknown '#{ab_subj}'"
           end
    
    @customer = customer
    @univ = univ
    @ab_body = ab_body
    @abtvid = abtvid
    @token = login_token
    mail(subject:     subj,
         to:         Rails.env == 'production' ? customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM).deliver
    
  end


  # Send messages recommending particular titles
  #
  # To test:
  #    SfMailer.browsed(:customer => Customer.xyz,
  #                           :browsed_titles_by_cat => { Category[1] => [ Video[1], Video[2] ],
  #                                                       Category[2] => [ Video[1], Video[2] ] },
  #                           :toprated_titles_by_cat => { Category[1] => [ Video[1], Video[2] ],
  #                                                       Category[2] => [ Video[1], Video[2] ] },
  #                           :token => "TTTT",
  #                           :ctcode => "CCCC")
  def browsed( args )
    args.assert_valid_keys( :customer, :browsed_titles_by_cat, :toprated_titles_by_cat, :token, :ctcode )
    @customer = args[:customer]
    @browsed_titles_by_cat = args[:browsed_titles_by_cat]
    @toprated_titles_by_cat = args[:toprated_titles_by_cat]
    @token = args[:token]
    @ctcode = args[:ctcode]
    
    first_browsed_title = args[:browsed_titles_by_cat].map { |key, val| val }.flatten.first
    
    @args = args
    mail(subject:     "How-to DVDs at SmartFlix like \"#{first_browsed_title.name}\"",
         to:         Rails.env == 'production' ?  args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM
         ).deliver
  end


  def wishlist_discount_offer(to, product_id, discount_link)
    @customer = to
    @discount_product_id = product_id
    @discount_link = discount_link
    mail(subject:    "SmartFlix.com: Wishlist Discount!",
         to:        Rails.env == 'production' ?  customer.email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end


  ##################################################
  #  late, latecharge, lostcharge, etc.
  #

  def first_overdue_email(args)
    args.assert_valid_keys( :customer, :copies, :weekly_rate )
    @customer = args[:customer]
    @copies = args[:copies]
    @weekly_rate = args[:weekly_rate]
    
    @args = args
    
    mail(subject:    "SmartFlix.com: overdue DVDs",
         to:        Rails.env == 'production' ? args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER ,
         from:       SmartFlix::Application::EMAIL_FROM).deliver
  end

  #========================================
  #   university stuff
  #========================================
  
  # Send welcome email
  def university_welcome(university_name, university_hostname, customer)
    @name = customer.full_name
    @university = university_name
    @university_url = university_hostname && "http@//#{university_hostname}.com/"
    mail(subject:    "Welcome to #{university_name}",
         to:        Rails.env == 'development' ? SmartFlix::Application::EMAIL_TO_DEVELOPER : customer.email,
         from:       SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  def cc_expire_warn_univ( args )
    args.assert_valid_keys( :customer, :order, :copies, :monthly_rate, :details )
    @customer = args[:customer]
    @order = args[:order]
    @copies = args[:copies]
    @monthly_rate = args[:monthly_rate]
    @details = args[:details]
    
    @customer = args[:customer]
    @order = args[:order]
    @copies = args[:copies]
    @monthly_rate = args[:monthly_rate]
    @details = args[:details]
    
    mail(subject:     "SmartFlix: Credit Card Expiration Warning - Don't get charged!",
         to:         Rails.env == 'production' ?  args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  def unpaid_univ( args )
    args.assert_valid_keys( :customer, :order, :copies, :monthly_rate, :details )
    @customer = args[:customer]
    @order = args[:order]
    @copies = args[:copies]
    @monthly_rate = args[:monthly_rate]
    @details = args[:details]
    
    @customer = args[:customer]
    @order = args[:order]
    @copies = args[:copies]
    @monthly_rate = args[:monthly_rate]
    @details  = args[:details]
    
    
    
    mail(subject:     'SmartFlix: monthly charge for University',
         to:         Rails.env == 'production' ?  args[:customer].email : SmartFlix::Application::EMAIL_TO_DEVELOPER,
         from:        SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  # we've added an item to your subscription; you might want to cancel it
  def university_item_added(customer, university, product)
    @customer = customer
    @university = university
    @product = product
    mail(subject:    "Item added to #{university.name}",
         to:        Rails.env == 'development' ? SmartFlix::Application::EMAIL_TO_DEVELOPER : customer.email,
         from:       SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  # you've got items in your queue, but no good CC
  def university_recover(customer, university)
    @customer = customer
    @university = university
    mail(subject:    "We miss you! #{university.name}",
         to: Rails.env == 'development' ? SmartFlix::Application::EMAIL_TO_DEVELOPER : customer.email,
         from:       SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  # you've got items in your queue, but no good CC
  def univ_queue_low(customer, order)
    @customer = customer
    @university = order.university
    mail(subject:    "Your queue is running low",
         to: Rails.env == 'development' ? SmartFlix::Application::EMAIL_TO_DEVELOPER : customer.email,
         from:       SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
  end

  def univ_mistaken_charge(customer, order)
    @customer = customer
    @university = order.university
    mail(subject:    "Possible mistaken charge - we apologize, and will reverse it if needed ",
         to: Rails.env == 'development' ? SmartFlix::Application::EMAIL_TO_DEVELOPER : customer.email,
         from:       SmartFlix::Application::EMAIL_FROM_SUPPORT).deliver
    
  end

end

SmartFlix::Application.routes.draw do

  # # RSS catch
  # match "store/new(/:id(/:misc)).rss",  :to => "help#index"


  # #----------
  # # plugins with routes
  # #     these all need to come before the generic admin resources
  # #----------

  # NewsletterEditor.add_routes(binding, "admin")
  # DevelBarRoutes.add_routes(binding, "admin")

  # match ""                                   => "store#index",                       :as => :home

  # match "univstore/all"                      => "univstore#all",                     :as => :univstore_all
  # match "univstore/one/:univ_id"             => "univstore#one",                     :as => :univstore_one
  # match "univstore/welcome_back/:univ_id"    => "univstore#welcome_back",            :as => :univstore_welcome_back
  # match "univstore/welcome_back_done"     => "univstore#welcome_back_done",            :as => :univstore_welcome_back_done
  # match "univstore/:action/:univ_id"         => "univstore#index"
  # match "univstore/:action/:univ_id/:name"   => "univstore#index"

  # match "store/suggest"                      => "store#suggest"
  # match "store/:action/:id/:name"            => "store#index"
  # match "store/video/:id"                    => "store#video",                       :as => :video
  # match "store/:action/:id"                  => "store#index"
  # match "store/:action"                      => "store#index"
  # match "store/review/:id"                   => "store#review", :as => :ratings
  # match "store/expand_univ_element/:id"                   => "store#expand_univ_element", :as => :store_expand_univ_element
  # match "giftcard"                           =>  "store#giftcard"

  # match "cart/delete/:type/:id"              => "cart#delete",                       :as => :cart_delete
  # match "cart"                               => "cart#index",                        :as => :cart
  # match "checkout"                           => "cart#checkout",                     :as => :checkout

  # match "help/:action/:id"                   => "help#index"

  # match "customer/manage_cc"                 => "customer#manage_cc",                :as => :customer_manage_cc
  # match "customer/password_change"           => "customer#password_change",          :as => :customer_password_change
  # match "customer/password_reset"            => "customer#password_reset",           :as => :customer_password_reset
  # match "customer/email_prefs"               => "customer#email_prefs",              :as => :customer_email_prefs
  # match "customer/wheres_my_stuff"           => "customer#wheres_my_stuff",          :as => :customer_wheres_my_stuff
  # match "customer/try_card_again/:card_id/"  => "customer#try_card_again",           :as => :customer_try_card_again
  # match "customer/change_plan/:order_id/:num_dvds"  => "customer#ajax_change_plan",       :as => :customer_change_plan

  # match "customer/report_problem/"            => "customer#report_problem",       :as => :customer_report_problem
  # match "customer/report_problem_2/:line_item_id"      => "customer#report_problem_2",       :as => :customer_report_problem_2
  # match "customer/report_problem_3/:line_item_id"      => "customer#report_problem_3",       :as => :customer_report_problem_3

  # match "customer/university_status_all"     => "customer#university_status_all",       :as => :customer_university_status_all
  # match "customer/university_status/:id"     => "customer#university_status",       :as => :customer_university_status

  # match "customer/university_cancel/:id"     => "customer#university_cancel",       :as => :customer_university_cancel

  # match "customer/ajax_hide_firsttimer_box"  => "customer#ajax_hide_firsttimer_box", :as => :customer_ajax_hide_firsttimer_box
  # match "customer/ajax_set_emailaddr"        => "customer#ajax_set_emailaddr",       :as => :customer_ajax_set_email_addr
  # match "customer/ajax_univ_move_to_top/:id" => "customer#ajax_univ_move_to_top",    :as => :ajax_univ_move_to_top
  # match "customer/ajax_univ_duplicate/:id"   => "customer#ajax_univ_duplicate",      :as => :ajax_univ_duplicate
  # match "customer/ajax_univ_cancel_li/:id"   => "customer#ajax_univ_cancel_li",      :as => :ajax_univ_cancel_li
  # match "customer/ajax_univ_uncancel_li/:id" => "customer#ajax_univ_uncancel_li",    :as => :ajax_univ_uncancel_li
  # match "customer/view_again/:id"            => "customer#view_again",               :as => :view_again
  # match "customer/account_info"              => "customer#account_info",             :as => :customer_account_info

  # match "customer/:action/:id"               => "customer#index"
  # match "customer/:action"                   => "customer#index"

  # match "store/new"                          => "store#new"


  # resources :comments
  # resources :customers
  # resources :products
  # resources :authors
  # resources :vendors
  # resources :product_sets
  # resources :video_assets
  # resources :people
  # resources :purchasing
  # resources :copies
  # resources :timeshets
  # resources :ab_tests

  #----------
  # admin
  #----------
  namespace :admin do
    match "customers/small_claims/:id" => "customers#small_claims", :as =>:customer_smallclaims
    match "customer/credit_account"    => "customers#credit_customer_account", :as => :customer_credit_account
    match "customers/add_note"         => "customers#add_note"

    match "timesheets/show"            => "timesheets#show", :as => :timesheets_show

    match "persons/login"              => "persons#login"
    match "persons/logout"             => "persons#logout"

    match "shipments/ship"             => "shipments#ship"
    match "shipments/scan_out"         => "shipments#scan_out"  , :as => :scan_out
    match "shipments/print"            => "shipments#print"        , :as => :ship_print

    match "purchasings"                => "purchasings#index"
    match "purchasings/polishable"     => "purchasings#polishable"

    match "copies/returns"             => "copies#returns"    , :as => :returns
    match "copies/return_one"          => "copies#return_one" , :as => :return_one
    match "copies/update_status"       => "copies#update_status"

    match "reviews"       => "reviews#index", :as => :reviews

    match "credit_cards/again/:id"       => "credit_cards#try_again", :as => :try_cc_again



    match "inventories/start"       => "inventories#start", :as => :inventory_start
    match "inventories/in_progress"       => "inventories#in_progress", :as => :inventory_in_progress
    match "inventories/scan_dvd"       => "inventories#scan_dvd", :as => :inventory_scan_dvd

    [ 
     "authors",
     "addresses",
     "categories",
     "copies",
     "customers",
     "inventories",
     "orders",
     "giftcerts",
     "payments",
     "persons",
     "product_bundles",
     "product_sets",
     "products",
     "shipments",
     "timesheets",
     "universities",
     "vendors",
    ].each do |noun|    
      resources noun
    end

    match "copies/search"                                   => "copies#search",                       :as => :copies_search

  end
  match "admin/"                           => "admin/customers#index"


  # #----------
  # # deprecated features
  # #----------
  # match "projects"                                 => "store#index"
  # match "contest/show/:id"                         => "store#index"
  # match "profiles/:id"                             => "store#index"
  # match "projects"                                 => "store#index"
  # match "contest/image_lightbox/:id"               => "store#index"
  # match "projects/image_lightbox/:id"               => "store#index"


  # #----------
  # # defaults
  # #----------

  match "/:controller(/:action(/:id))", :controller => /admin\/[^\/]+/
  # match "/:controller(/:action(/:id))"

  #----------
  # turn Smartflix off 7 Feb 2016
  #----------

  match '(*foo)' => 'turnitoff#turnitoff'
end

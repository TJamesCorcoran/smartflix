require "#{File.dirname(__FILE__)}/../test_helper"

class UnivStore < ActionController::IntegrationTest
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  @wood_cat = nil
  @wood_univ = nil

  @metal_cat = nil
  @metal_univ = nil


  @plastic_vid = nil

  def setup
    AbTester.create_test(:funnel_type,  8, 0.0, [:old, :new_with_indivs, :new_univs_only],  true)
    Category.destroy_all
    UnivStub.destroy_all
    University.destroy_all
    Product.destroy_all

    @wood_cat = Category.create!(:description => "wood cat", :name => "wood", :parent_id => 0)
    @wood_univ = University.create_new(:name => "wood",
                                       :domains => [],
                                       :title_id_list =>  [ Video.create!(:name => "wood1", :description=>"foo", :date_added => Date.today, :purchase_price => 40, :categories => [ @wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                            Video.create!(:name => "wood2", :description=>"foo", :date_added => Date.today, :purchase_price => 50, :categories => [ @wood_cat ], :author_id => 1, :vendor_id =>1).id,
                                                            Video.create!(:name => "wood3", :description=>"foo", :date_added => Date.today, :purchase_price => 60, :categories => [ @wood_cat ], :author_id => 1, :vendor_id =>1).id],
                                       :category => @wood_cat,
                                       :price => 22.95)
    @wood_univ.products.each { |prod| 
      prod.categories << @wood_cat
      prod.save!
    }

    @metal_cat = Category.create!(:description => "metal cat", :name => "metal",  :parent_id => 0)
    @metal_univ = University.create_new(:name => "metal",
                                       :domains => [],
                                       :title_id_list =>  [ Video.create!(:name => "metal1", :description=>"foo", :date_added => Date.today, :purchase_price => 40, :categories => [ @metal_cat ], :author_id => 1, :vendor_id =>1).id,
                                                            Video.create!(:name => "metal2", :description=>"foo", :date_added => Date.today, :purchase_price => 50, :categories => [ @metal_cat ], :author_id => 1, :vendor_id =>1).id,
                                                            Video.create!(:name => "metal3", :description=>"foo", :date_added => Date.today, :purchase_price => 60, :categories => [ @metal_cat ], :author_id => 1, :vendor_id =>1).id],
                                       :category => @metal_cat,
                                       :price => 22.95)
    @metal_univ.products.each { |prod| 
      prod.categories << @metal_cat
      prod.save!
    }

    @plastic_cat = Category.create!(:description => "plastic cat", :name => "plastic",  :parent_id => 0)
    @plastic_vid = Video.create!(:name => "plastic1", :description=>"foo", :date_added => Date.today, :purchase_price => 40, :categories => [ @plastic_cat ], :author_id => 1, :vendor_id =>1)

  end

  def re
    reset!
    Customer.destroy_all
  end

  def util_do_gets_test_results(index_redirs, cat_redirs, video_redirs)
    verbose = false
    #----------
    # index
    #
    puts "=== index" if verbose
    request_via_redirect(:get, "/store/")
    assert_template  (index_redirs ?   "univstore/index": "store/index"     )

    #----------
    # cat
    #
    puts "=== cat" if verbose

    [ @wood_cat, @metal_cat ].each do |cat|
      request_via_redirect(:get, "/store/category/#{cat.id}")
      assert_template  (cat_redirs ?   "univstore/one": "store/category"     )
    end

    #----------
    # videos
    #
    puts "=== vid" if verbose
    [ @wood_cat, @metal_cat ].each do |cat|
      cat.products.each do |prod|
        request_via_redirect(:get, "/store/video/#{prod.id}")
        assert_template  (video_redirs ?   "univstore/one": "store/video"     )
      end
    end

    # in all cases, a video that has no associated univ should stay at the video 
    request_via_redirect(:get, "/store/video/#{@plastic_vid.id}")
    assert_template  ("store/video") 


  end


  def test_redirect

    verbose = false

    #----------
    # old style: 
    #    index -> index
    #    cat   -> cat
    #    video -> video
    #
    puts "========== old" if verbose
    $AB_TEST_HACK_RESULTS = {:funnel_type => :old}
    util_do_gets_test_results(false, false, false)


    #----------
    # new_with_indivs: 
    #    index -> UNIV
    #    cat   -> UNIV
    #    video -> video
    #
    puts "========== new_with_indivs" if verbose
    $AB_TEST_HACK_RESULTS = {:funnel_type => :new_with_indivs}
    util_do_gets_test_results(true, true, false)

    #----------
    # new_univs_only: 
    #    index -> UNIV
    #    cat   -> UNIV
    #    video -> UNIV
    #
    puts "========== new_univs_only" if verbose
    $AB_TEST_HACK_RESULTS = {:funnel_type => :new_univs_only}
    util_do_gets_test_results(true, true, true)

  end

  def util_univstore_login(username, pwd, univ)
    
    univ_id = nil
    if univ.nil?
      univ_id = nil  
    elsif univ.is_a?(Fixnum)
      univ_id = univ
    elsif univ.is_a?(University)
      univ_id = univ.id
    else
      raise "unknown univ #{univ.inspect} - expect int or univ"
    end
    
    request_via_redirect(:post, 
                         "/univstore/new_signup", 
                         { :customer => {:email => username, :email_2 => username, :password => pwd, :password_2 => pwd},
                           :university => { :university_id => univ_id },
                           :src_controller => "univstore",
                           :src_action => "index",
                           :src_id => nil} )

  end

  def util_create_cust(with_addr = false, with_good_cc = false, with_bad_cc = false)
    existing = Customer.create!(:email => "existing_user@smartflix.com",
                                :password => "12345",
                                :password_confirmation => "12345",
                                :arrived_via_email_capture => 1,
                                :first_ip_addr => "127.0.0.1",
                                :first_server_name => "smartflix.com")

    if with_addr
    billing_addr = Address.test_billing_addr
    billing_addr.save!
    shipping_addr = Address.test_shipping_addr
    shipping_addr.save!
    existing.shipping_address_id = shipping_addr.id
    existing.billing_address_id = billing_addr.id
    existing.save!
    end

    if with_good_cc
      existing.credit_cards << CreditCard.test_card_good
      existing.save!
    end

    if with_bad_cc
      existing.credit_cards << CreditCard.test_card_bad
      existing.save!
    end

    existing
  end
  

  def test_univstore_login
    $AB_TEST_HACK_RESULTS = {:funnel_type => :new_univs_only}
    $NO_UNIV_ERROR_STR = "You must pick a university."
    
    # === new user, univ
    re
    util_univstore_login("new_user@smartflix.com", "12345", University.first)

    assert_template 'set_address'
    assert_equal(nil, flash[:message])    
    assert_equal(Customer.first.id, session[:customer_id])
    assert_equal(University.first.id, session[:univ_id].to_i)
    
    # === just user, no univ
    re
    util_univstore_login("new_user@smartflix.com", "12345", nil)

    assert_template 'index'
    assert_equal($NO_UNIV_ERROR_STR, flash[:message])
    assert_equal(Customer.first.id, session[:customer_id])
    assert_equal(nil, session[:univ_id])
    
    # === no user, just univ
    re
    util_univstore_login("", "", University.first)
    
    assert_template 'index'
    assert_equal(nil, flash[:message])
    assert_equal(nil, session[:customer_id])
    assert_equal(University.first.id, session[:univ_id].to_i)
    
    
    
    
    # === no user, no univ
    re
    util_univstore_login("", "", nil)
    
    assert_template 'index'
    assert_equal($NO_UNIV_ERROR_STR, flash[:message])
    assert_equal(nil, session[:customer_id])
    assert_equal(nil, session[:univ_id])
    
    
    # === existing user, no univ
    re
    existing = util_create_cust(true, false)    

    util_univstore_login("existing_user@smartflix.com", "12345", nil)

    assert_template 'index'    
    assert_equal($NO_UNIV_ERROR_STR, flash[:message])
    assert_equal(existing.customer_id, session[:customer_id])
    assert_equal(nil, session[:univ_id])
    
    # === existing user (bad pwd), no univ
    re
    existing = util_create_cust(false, false)

    util_univstore_login("existing_user@smartflix.com", "wrong_pwd", nil)
    
    assert_equal("Customer exists, but incorrect password", flash[:message])
    assert_equal(nil, session[:customer_id])
    assert_equal(nil, session[:univ_id])

    # === existing user, univ, no addr
    re
    existing = util_create_cust(false, false)

    util_univstore_login("existing_user@smartflix.com", "12345", University.first.id)

    assert_template 'set_address'    
    assert_equal(nil, flash[:message])
    assert_equal(existing.customer_id, session[:customer_id])
    assert_equal(University.first.id, session[:univ_id].to_i)

    # === existing user, univ, addr
    re
    existing = util_create_cust(true, false)

    util_univstore_login("existing_user@smartflix.com", "12345", University.first.id)

    assert_template 'set_cc'    
    assert_equal(nil, flash[:message])
    assert_equal(existing.customer_id, session[:customer_id])
    assert_equal(University.first.id, session[:univ_id].to_i)

#     # === existing user, univ, addr, good cc
#     re
#     existing = util_create_cust(true, true)

#     util_univstore_login("existing_user@smartflix.com", "12345", University.first.id)

#     assert_template 'done'    
#     assert_equal(nil, flash[:message])
#     assert_equal(existing.customer_id, session[:customer_id])
#     assert_equal(University.first.id, session[:univ_id].to_i)

#     # === existing user, univ, addr, bad cc
#     re
#     existing = util_create_cust(true, false, true)

#     util_univstore_login("existing_user@smartflix.com", "12345", University.first.id)

#     assert_template 'set_cc'    
#     assert_equal(nil, flash[:message])
#     assert_equal(existing.customer_id, session[:customer_id])
#     assert_equal(University.first.id, session[:univ_id].to_i)

  end



end


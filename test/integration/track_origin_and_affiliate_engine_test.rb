require File.dirname(__FILE__) + '/../test_helper'





class TrackOriginTest < ActionController::IntegrationTest

  @@silent_logger = lambda { |x| }
  
  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  
  def setup
    # reset the date
    Date.force_today

    Order.destroy_all
    LineItem.destroy_all
    Payment.destroy_all
    AffiliateTransaction.destroy_all
  end

  
  def test_index  
    
    verbose = false
    
    [
     { :name => "basic", :throw => false },
     { :name => "basic_with_create", :throw => false, :create_new_cust => true },
     { :name => "error_handling", :throw => true }
     
    ].each do |test_case|
      
      setup
      reset!
      
      open_session do |user|
        
        puts "========== #{test_case[:name]}" if verbose
        
        if test_case[:throw] 
          TrackOrigin.set_pre_action( lambda { throw "intentional error for testing" })
        else
          TrackOrigin.set_pre_action( lambda {} )
        end
        
        #----------
        # first get: go in with
        #    * no session
        #    * a CT code
        
        affiliate = customers(:four)
        
        referer = "http://google.com"
        
        # flush out all the email messages sent by actionmailer, so that we can look
        # just at emails that this test sends
        
        ActionMailer::Base.deliveries = []
        
        first_response = get("/store/?ct=af#{affiliate.id}", {}, {:referer => referer} )
        
        if test_case[:throw]         
          all_msgs = ActionMailer::Base.deliveries
          assert_equal(1, all_msgs.size, all_msgs[1].inspect)
          msg = all_msgs.first
          assert(msg.subject.match(/store#index.*uncaught throw.*intentional error for testing/))
          assert(msg.to.first.match(/xyz@smartflix.com/))
          assert(msg.body.match(/track_origin_and_affiliate_engine_test.rb/), msg.body)
          next
        end
        
        # we want a 301 redirect so that google understands that these are equal
        #   * smartflix.com/                             
        #   * smartflix.com/?ct=af200001
        assert_redirected_to(:action => :index)
        assert_equal(status, 301)
        
        # we also want to have stuffed the origin_uri and the referer into the session
        assert_equal(referer,               session[:origin_referer]) 
        assert_equal("/store/?ct=af#{affiliate.id}", session[:origin_uri])
        assert_equal(nil,                   session[:origin_id]) 
        
        #----------
        # second get: go in with
        #    * a session cookie in the browser
        #    * a session db entry at the server
        #    * the CT code stripped from URL
        
        get ("/store")
        
        assert(            session[:origin_id])       # we've created an Origin obj
        assert_equal(nil,  session[:origin_referer])  # ...and removed this from session
        assert_equal(nil,  session[:origin_uri])      # ...and removed this from session
        
        origin = Origin[session[:origin_id]]
        assert_equal(referer,               origin.referer) 
        assert_equal("/store/?ct=af#{affiliate.id}", origin.first_uri)
        assert_equal(nil, origin.customer_id)
        
        #----------
        # third: login
        #    * we now have a customer_id, so ...
        #    * we can store it in the origin object in the db
        customer = nil
        if test_case[:create_new_cust]
          util_create_new_customer(:country_id => 223,
                                   :pwd => "12345" ,
                                   :email => "test@smartflix.com" ,
                                   :name_first => "joe",
                                   :name_last => "blow",
                                   :addr_1 => "7 central st",
                                   :addr_2 => "suite 140",
                                   :city => "arlington",
                                   :state_id => 1,  
                                   :zip => "02474")
          customer = Customer.last
        else
          customer = customers(:bob)
          util_login(customer.email, "password")
        end
        
        assert(            session[:origin_id])
        origin = Origin[session[:origin_id]]
        assert_equal(customer.id, origin.customer_id)
        
        #----------
        # do some shopping
        util_add_item_to_cart(Product.first)
        util_place_order({ :cc_num =>"370000000000002",
                           :cc_month => Date.today.month,
                           :cc_year => Date.today.year,
                           :expect_success => true})
        
        
        #----------
        # we haven't run the affiliate script yet, so we don't expect anything
        
        assert_equal([], affiliate.affiliate_transactions)
        
        #----------
        # run the affiliate engine
        AffiliateEngine.credit_affiliates
        
        #----------
        # now we expect the transaction to show up
        
        affiliate.reload
        aff_trans = affiliate.affiliate_transactions
        assert_equal(1, aff_trans.size)
        
        one_tran = aff_trans.first
        assert_equal("C", one_tran.transaction_type)
        assert_equal(customer, one_tran.referred_customer)
        assert_equal(5.0, one_tran.amount)
        assert_equal(Date.today, one_tran.date)
        
        #---------- 
        # run the affiliate engine a second time
        AffiliateEngine.credit_affiliates
        
        #----------
        # we don't want to see a second transaction!
        
        affiliate.reload
        aff_trans = affiliate.affiliate_transactions
        assert_equal(1, aff_trans.size)
        
      end
    end
  end
  
  # university orders get more compensation than regular orders ... but take 2 months to do so
  #
  def test_affiliate_univ

    OverdueEngine.logger = @@silent_logger
    AffiliateEngine.logger = @@silent_logger

    verbose = false
    affiliate = Customer[6000]
    
    [ 
#      { :name => "no purchase",   :item => nil,                   :customer => Customer[1], :total => 0.0 },
      { :name => "item: $5 fee",  :item => Video.find(:first),    :customer => Customer[2], :total => 5.0 },
      { :name => "univ: month 0", :item => UnivStub.find(:first), :customer => Customer[3], :iter_months => 0, :total => 0.0 },
      { :name => "univ: month 1", :item => UnivStub.find(:first), :customer => Customer[4], :iter_months => 1, :total => 20.0 },
      { :name => "univ: month 2", :item => UnivStub.find(:first), :customer => Customer[5], :iter_months => 2, :total => 20.0 }
      
    ].each do |test_case|

      puts "========== #{test_case[:name]}" if verbose 
      
      # reset the session
      reset!
      setup

      cust = test_case[:customer]
      cust.credit_cards = []
      good_cc = CreditCard.test_card_good
      cust.credit_cards << good_cc
      cust.reload


      #----------
      # #1: get a first page w a CT code
      first_response = get("/store/?ct=af#{affiliate.id}", {}, {:referer => "http://google.com"} )
      
      
      # we want a 301 redirect so that google understands that these are equal
      #   * smartflix.com/                             
      #   * smartflix.com/?ct=af200001
      assert_redirected_to(:action => :index)
      
      get ("/store")
      
      
      #----------
      # #2: login
      #    * we now have a customer_id, so ...
      #    * we can store it in the origin object in the db
      customer = test_case[:customer]
      
      util_login(customer.email, "password")

      #----------
      # #3: do some shopping
      item = test_case[:item]
      if item
        util_add_item_to_cart(item)
        util_place_order({ :cc_num =>"370000000000002",
                             :cc_month => Date.today.month,
                             :cc_year => Date.today.year,
                             :expect_success => true})
      end
      
      #----------
      # we haven't run the affiliate script yet, so we don't expect anything
      
      assert_equal([], customer.affiliate_referral_transactions)
      
      #----------
      # allow time to pass 
      #   ... and charge univs, once per month
      if test_case[:iter_months]
        puts "Iterating date >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" if verbose
        test_case[:iter_months].times { |ii|
          Date.force_today(Date.today >> 1)
          puts "  * #{Date.today}" if verbose
          OverdueEngine.bill_univ_students
        }
      end
      

      #----------
      # run the affiliate engine
      AffiliateEngine.credit_affiliates

      
      
      #----------
      # now we expect the transaction to show up
      
      customer.reload
      refs = customer.affiliate_referral_transactions

      total = refs.inject(0.0) { |sum, t| sum + t.amount }

      assert_equal(test_case[:total], total)
      
      #---------- 
      # run the affiliate engine a second time
      AffiliateEngine.credit_affiliates
      
      #----------
      # we don't want to see a second transaction!
      
      affiliate.reload
      aff_trans = affiliate.affiliate_transactions
      assert_equal(test_case[:total], total)

      
    end
  end



end

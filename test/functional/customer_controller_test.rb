require File.dirname(__FILE__) + '/../test_helper'
# require 'customer_controller'

# Re-raise errors caught by the controller.
class CustomerController; def rescue_action(e) raise e end; end

class CustomerControllerTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup
    @controller = CustomerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index

    # Make sure login is required
    get :index
    assert_redirected_to :controller => 'customer', :action => 'login'
    assert_equal "Login is required", flash[:message]

    # Make sure OK if logged in customer
    get :index, {}, {:customer_id => 1, :timestamp => Time.now.to_i}

    assert_redirected_to :controller => 'customer', :action => 'wheres_my_stuff'

  end

  def test_login

    # Make sure responds to simple request
    get :login
    assert_response :success
    assert_template 'login'

    # Make sure login succeeds
    post :login, {:email => 'bob@bob.com', :password => 'password'}
    assert_redirected_to :controller => 'customer', :action => ''
    assert_equal(Customer.find_by_email('bob@bob.com').id, session[:customer_id])

    # And request for customer page now succeeds without requiring login
    get :index
    assert_redirected_to :controller => 'customer', :action => 'wheres_my_stuff'

  end

  def test_password_reset
    [
     'bob@bob.com',
     'partial@partial.com'
    ].each do |email_addr|
      
      cust = Customer.find_by_email(email_addr)
      old_password = cust.hashed_password
      
      # go to reset password page
      get :reset_password
      assert_response :success
      assert_template 'reset_password'
      assert_tag :tag => 'div', :attributes => { :id =>"pre-reset-password" }
      
      # click button
      post :reset_password, {:email => email_addr}
      assert_response :success
      assert_template 'reset_password'
      assert_tag :tag => 'div', :attributes => { :id =>"post-reset-password" }
      
      # verify that a reset_url is specified
      reset_url = assigns['reset_url']
      assert reset_url
      reset_url.match(/\?token=(.*)/)
      token = $1
      
      #     # now go to the url which was emailed to us; do it wrong
      #     get assigns['reset_url']
      #     assert_redirected_to :controller => 'customer', :action => 'login'
      #     post :password, {:customer_password => 'new_password_12345',  :customer_password_confirmation => 'xxx'}
      #     assert_equal "Login is required", flash[:message]
      
      # website should strip off the auth token and redirect
      get :password, :token => token
      assert_response :success
      post :password, {:token => token, :customer => {:password => 'new_password_12345', :password_confirmation => 'new_password_12345'}}
      assert_redirected_to :controller => 'customer', :action => 'login'
      assert_equal "Your password has successfully been changed!", flash[:message]
      
      new_password = cust.reload.hashed_password    
      assert old_password != new_password
    end
  end

  def test_new_customer

    # Make sure always redirects on non-post
    get :new_customer
    assert_redirected_to :controller => 'customer', :action => 'login'

    # Make sure correct parameters leads to a valid customer
    post :new_customer, {
      :customer => { :email => 'newby@smartflix.com', :password => 'password' },
      :address => { :first_name => 'Nev', :last_name => 'By', :address_1 => '123 Doom St.', :address_2 => '',
                    :city => 'Doomville', :state_id => 1, :postcode => '12345', :country_id => 223 },
      :email_notifications => 1
    }
    assert_redirected_to :controller => 'customer', :action => ''
    assert_equal(Customer.find_by_email('newby@smartflix.com').id, session[:customer_id])
    assert_equal "New customer account created", flash[:message]
    
  end

  def test_address

    # Make sure login is required
    get :address
    assert_redirected_to :controller => 'customer', :action => 'login'
    assert_equal "Login is required", flash[:message]
    flash.clear

    # Make sure simple get is OK if logged in customer
    get :address, { :id =>  1 }, {:customer_id => 1, :timestamp => Time.now.to_i}
    assert_response :success
    assert_template 'address'
    assert_select 'span.error-span', false

    # Make sure can't get someone elses address
    get :address, { :id =>  3 }, {:customer_id => 1, :timestamp => Time.now.to_i}
    assert_response :success
    assert_template 'address'
    assert_select 'span.error-span', 'Error: Could not find address'

    # Make sure can make simple change
    assert_equal(Customer.find(1).shipping_address.postcode, '12345')
    post :address, { :id => 1, :address => { :postcode => '54321' } }, { :customer_id => 1, :timestamp => Time.now.to_i }
    assert_redirected_to :controller => 'customer', :action => 'address', :id => nil
    assert_equal(Customer.find(1).shipping_address.postcode, '54321')    

  end

  def test_manage_cc

    # Make sure responds to simple request
    get :manage_cc
    assert_redirected_to :controller => 'customer', :action => 'login'

    # Make sure OK if logged in customer
    resp = get :manage_cc, {}, {:customer_id => 7, :timestamp => Time.now.to_i}
    assert ! resp.body.match(/no credit cards on file/)
    lines = resp.body.split(/\n/)
    radio_lines = lines.select { |line| line.match(/radio/)}

    # we have 3 cards, but one is historical and does not have a last-four-digits associated with it.  Make sure that it's not displayed.
    assert_equal 3, radio_lines.size
    assert_equal 1, radio_lines.select { |line| line.match(/input .*card_choice_credit_card_1111/)}.size
    assert_equal 1, radio_lines.select { |line| line.match(/input .*card_choice_credit_card_2222/)}.size
    assert_equal 1, radio_lines.select { |line| line.match(/input .*card_choice_credit_card_new/)}.size

    # successfully change the expir date on card x1111
    post :manage_cc, { :customer_id => 7, :card_choice => "credit_card_1111" , "credit_card_1111"=>{"month"=>"1", "year"=>"2021", "last_four" => "1111"} }
    assert_response :success
    assert_equal 2, customers(:manage_cc_test).reload.credit_cards.select { |cc| cc.last_four == "1111" }.size 
    assert_equal 1, customers(:manage_cc_test).reload.credit_cards.select { |cc| cc.last_four == "1111" && cc.year == 2021}.size

    # successfully create a new card
    post :manage_cc, { :customer_id => 7, :card_choice => "credit_card_new" , "credit_card_new"=>{"month"=>"7", "year"=>"2091", "number" => "4111111111111111"} }
    assert_response :success
    assert_equal 1, customers(:manage_cc_test).reload.credit_cards.select { |cc| cc.last_four == "1111" && cc.year == 2091 && cc.month == 7}.size

    # unsuccessfully try to update the card w nil last_four
#    resp = post :manage_cc, { :customer_id => 8, :card_choice => "credit_card_" , "credit_card_"=>{"month"=>"1", "year"=>"2021", "number" => "4111111111111111"} }
#    assert_equal "ERROR: Couldn't find that credit card", flash[:message]
  end

  # XXXFIX P2: Finish these tests for other actions

end

# Tests for lib/tvr/abandoned_basket_engine.rb

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/abandoned_basket_engine'

class TestAbandonedBasketEmails < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  
  def setup
    # AbandonedBasketEngine.logger = method(:puts)   
    AbandonedBasketEngine.logger = lambda { |x| }

    @emails = ActionMailer::Base.deliveries
    @emails.clear
    ENV['SKIP_PULL']='true'
  end
  
  def test_mailer
    customer = Customer.find(1)
    products_in_cart = customer.carts.map(&:cart_items).flatten
    
    # Make sure the mail at least gets created
    assert mail = Mailer.create_abandoned_basket( customer, customer.carts.first )
    
    # Make sure that the products actually get into the body
    assert_match Regexp.compile( products_in_cart[0].product.name ), mail.body
    
    # Make sure the the customer's email address is properly inserted
    assert_match Regexp.compile( customer.email ), mail.body
  end
  
  def test_sends_email
    @emails.clear

    AbandonedBasketEngine.abandoned_basket_emails


    # Cart 1 - Already received email
    # Cart 2 +
    # Cart 3 - Items too new
    # Cart 4 - No created_ats on items
    assert_equal 1, @emails.size, @emails.inspect
    email = @emails[0]
    @emails.clear
    
    # Make sure that it marked the customers and ignores them this time
    AbandonedBasketEngine.abandoned_basket_emails
    assert_equal 0, @emails.size

    # Check that the subject matches
    assert_equal "Your SmartFlix.com Shopping Cart", email.subject
    
    # Check that it got sent to the right address
    assert_equal Customer.find(2).email, email.to[0]
    
    # Make sure that the proper items were injected into the template
    assert_match Regexp.compile( Customer.find(2).carts.map(&:cart_items).flatten.map(&:product)[0].name ), email.body    
  end
  
#   def test_leaves_out_newer_items
#     AbandonedBasketEngine.abandoned_basket_emails
#     # make sure none match Cart 3
#     assert_equal [], @emails.select{|e| e.to[0] == Cart.find(3).customer.email}
#   end
  
  def test_tolerates_blank_created_at
    AbandonedBasketEngine.abandoned_basket_emails
    
    # make sure none match Cart 4
    assert_equal [], @emails.select{|e| e.to[0] == Cart.find(4).customer.email}
  end
  
end

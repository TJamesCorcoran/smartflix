require 'test_helper'

class CreditCardTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  # Make sure the validations fire
  def test_secure_setup
    customer = customers(:bob)
   
    credit_card_params = {
      :number => "4111111111111111",
      :last_four => "1111",
      :month => "1",
      :year => (Date.today.year + 2).to_s,
    }

    cc = CreditCard.secure_setup(credit_card_params, customer)
    assert cc.original_valid?
  end

  # def test_extra_attempts      
  #   cc = CreditCard.test_card_good

  #   assert_equal(0, cc.extra_attempts)

  #   cc.decr_extra_attempts

  #   assert_equal(0, cc.extra_attempts)

  #   cc.incr_extra_attempts
  #   cc.incr_extra_attempts

  #   assert_equal(2, cc.extra_attempts)

  #   cc.decr_extra_attempts

  #   assert_equal(1, cc.extra_attempts)
    
  # end


  def test_any_chance_of_working  
    assert_equal(true, credit_cards(:cc_no_statuses_live).any_chance_of_working?)
    assert_equal(true, credit_cards(:cc_no_statuses_live).any_chance_of_working?(true))

    assert_equal(false, credit_cards(:cc_no_statuses_expired).any_chance_of_working?)
    assert_equal(true, credit_cards(:cc_no_statuses_expired).any_chance_of_working?(true))

    assert_equal(false, credit_cards(:cc_one_status_expired).any_chance_of_working?)
    assert_equal(true, credit_cards(:cc_one_status_expired).any_chance_of_working?(true))

    assert_equal(false, credit_cards(:cc_one_status_expired).any_chance_of_working?)
    assert_equal(true, credit_cards(:cc_one_status_expired).any_chance_of_working?(true))

    assert_equal(true, credit_cards(:cc_one_status_gateway).any_chance_of_working?)
    assert_equal(true, credit_cards(:cc_one_status_gateway).any_chance_of_working?(true))

    assert_equal(false, credit_cards(:cc_one_status_addrnomatch).any_chance_of_working?)
    assert_equal(false, credit_cards(:cc_one_status_addrnomatch).any_chance_of_working?(true))
    
  end

#   def test_expiration_and_extrapolation      
    
#     initial_expir = Date.from_month_and_year(12, 2012 )

#     cc = CreditCard.create!(:customer_id => 5020,
#                             :brand => "master",
#                             :month => initial_expir.month,
#                             :year =>  initial_expir.year,
#                             :encrypted_number => "XXX",
#                             :number => "0000000000000000",
#                             :first_name => "fred",
#                             :last_name => "hacked 5424000000000015")

#     # base case: expect that extrapolated expir == actual expir
#     assert_equal(nil, cc.extrapolated_expiration_to_try)

#     # card is maxed out: should have no effect on date
#     sleep(1)
#     cc.payments << Payment.new( :amount => 9.99,
#                                 :amount_as_new_revenue => 9.99,
#                                 :complete => 1,
#                                 :successful => 0,
#                                 :updated_at => Time.now(),
#                                 :payment_method => "CreditCard",
#                                 :customer_id => 1,
#                                 :message =>  "This transaction has been declined")
    

#     assert_equal(nil, cc.extrapolated_expiration_to_try)

#     # card is expired; go +1 month
#     sleep(1)
#     cc.payments << Payment.new( :amount => 9.99,
#                                 :amount_as_new_revenue => 9.99,
#                                 :complete => 1,
#                                 :successful => 0,
#                                 :updated_at => Time.now(),
#                                 :payment_method => "CreditCard",
#                                 :customer_id => 1,
#                                 :message =>  "The credit card has expired")

# #RAILS3    assert_equal(initial_expir >> 1, cc.extrapolated_expiration_to_try)

#     # card is expired, we havne't tried hacking the date - still go just +1 month
#     sleep(1)
#     cc.payments << Payment.new( :amount => 9.99,
#                                 :amount_as_new_revenue => 9.99,
#                                 :complete => 1,
#                                 :successful => 0,
#                                 :updated_at => Time.now(),
#                                 :payment_method => "CreditCard",
#                                 :customer_id => 1,
#                                 :message =>  "The credit card has expired")
#     assert_equal(initial_expir >> 1, cc.extrapolated_expiration_to_try)

#     # this time try + 1 month, then expect suggestion of +2 month
#     sleep(1)
#     cc.payments << Payment.new( :amount => 9.99,
#                                 :amount_as_new_revenue => 9.99,
#                                 :complete => 1,
#                                 :successful => 0,
#                                 :updated_at => Time.now(),
#                                 :payment_method => "CreditCard",
#                                 :customer_id => 1,
#                                 :message =>  "The credit card has expired",
#                                 :cc_expiration => CcExpiration.date_to_expir(initial_expir >> 1))
#     assert_equal(initial_expir >> 2, cc.extrapolated_expiration_to_try)

#     #  try + 2 month, then expect suggestion of +3 month
#     sleep(1)
#     cc.payments << Payment.new( :amount => 9.99,
#                                 :amount_as_new_revenue => 9.99,
#                                 :complete => 1,
#                                 :successful => 0,
#                                 :updated_at => Time.now(),
#                                 :payment_method => "CreditCard",
#                                 :customer_id => 1,
#                                 :message =>  "The credit card has expired",
#                                 :cc_expiration => CcExpiration.date_to_expir(initial_expir >> 2))
#     assert_equal(initial_expir >> 3, cc.extrapolated_expiration_to_try)

#   end


end

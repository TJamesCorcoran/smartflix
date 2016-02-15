require 'test_helper'

class PaymentTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  def setup
  end

  def teardown
  end

  def util_charge(payment, expect)
    ret = payment.chargeable?
    assert_equal(ret , expect)
    payment.retry_attempts += 1 if ret
  end

  def test_chargeable    
    orig = Date.today

    p = Payment.create!(:order_id              => 1,
                        :customer_id           => 1,
                        :credit_card_id        => 1,
                        :payment_method        => "fake CC",
                        :amount                => 1.23,
                        :amount_as_new_revenue => 1.23,
                        :cart_hash             => "asd",
                        :complete              => false,
                        :successful            => false,
                        :status                => nil,
                        :retry_attempts        => 0,
                        :message               => "")
    

    #----------
    # day 1: we get 1 charge attempt
    # 
    Date.force_today(orig + 0)
    util_charge(p, true)
    util_charge(p, false)

    # day 2: nothing new
    #
    Date.force_today(orig + 1)
    util_charge(p, false)

    #----------
    # day 4: we get 1 more charge attempt
    # 
    Date.force_today(orig + 4)
    util_charge(p, true)
    util_charge(p, false)

    # day 5: nothing new
    #
    Date.force_today(orig + 5)
    util_charge(p, false)

    #----------
    # day 8: we get 1 more charge attempt
    # 
    Date.force_today(orig + 8)
    util_charge(p, true)
    util_charge(p, false)

    # day 9: nothing new
    #
    Date.force_today(orig + 9)
    util_charge(p, false)

    #----------
    # day 14: we get 1 more charge attempt
    # 
    Date.force_today(orig + 14)
    util_charge(p, true)
    util_charge(p, false)

    # day 15: nothing new
    #
    Date.force_today(orig + 15)
    util_charge(p, false)

    #----------
    # day 31: we get 1 more charge attempt
    # 
    Date.force_today(orig + 31)
    util_charge(p, true)
    util_charge(p, false)

    # day 131: nothing new
    #
    Date.force_today(orig + 131)
    util_charge(p, false)



  end

end

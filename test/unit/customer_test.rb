require 'test_helper'

class CustomerTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


  def setup
    Date.force_today(nil)
  end

  def teardown
    Date.force_today(nil)
  end




  # Make sure we can correctly reference the shipping and billing addresses
  def test_address    
    c = customers(:bob)
    assert_equal(addresses(:address1), c.shipping_address)
    assert_equal('Shipping Address', c.shipping_address.display_type)
    assert_equal(addresses(:address2), c.billing_address)
    assert_equal('Billing Address', c.billing_address.display_type)
  end

  # Make sure customers validate correctly
  def test_validations    
    c = Customer.new
    c.email = 'foo'
    c.first_name = 'A'
    c.last_name = 'A'
    c.password = 'foobar'
    c.password_confirmation = 'barfoo'
    assert !c.valid?
# XYZ FIX P4: get these validations back in (see app/models/customer.rb, line 52)
#    assert c.errors.invalid?(:first_name)
#    assert c.errors.invalid?(:last_name)
#    assert c.errors.invalid?(:email)
#    assert c.errors.invalid?(:password)
    # Different password error
    c.password = 'foo'
    c.password_confirmation = 'foo'
    assert !c.valid?
#    assert c.errors.invalid?(:password)
    # Password OK
    c.password = 'foobar'
    c.password_confirmation = 'foobar'
    assert !c.valid?
#    assert !c.errors.invalid?(:password)
    # Last name OK
    c.last_name = 'Aaron'
    assert !c.valid?
#    assert !c.errors.invalid?(:last_name)
    # First name OK
    c.first_name = 'Abernathy'
    assert !c.valid?
#    assert !c.errors.invalid?(:first_name)
    # Different email error, duplicate
    c.email = 'bob@bob.com'
    assert !c.valid?
#    assert c.errors.invalid?(:email)
    # Email OK, entire customer OK
    c.email = 'aaron@bob.com'
    assert c.valid?
#    assert !c.errors.invalid?(:email)
  end

  # Make sure we do proper authorization of address fetching
  def test_address_auth    
    c = customers(:bob)
    assert_equal(addresses(:address1), c.find_address(1))
    assert_equal(addresses(:address2), c.find_address(2))
    assert_nil(c.find_address(3))
    assert_nil(c.find_address(100000))
  end

  # Auth test for orders
  def test_orders_auth    
    c = customers(:bob)
    assert_equal(orders(:bob_order), c.find_order(1))
    assert_nil(c.find_order(2))
    assert_nil(c.find_order(100000))
  end

  # Auth test for line items
  def test_line_items_auth    
    c = customers(:bob)
    assert_equal(line_items(:bob_line_item), c.find_line_item(1))
    assert_nil(c.find_line_item(2))
    assert_nil(c.find_line_item(100000))
  end

  # Make sure names for display are correct
  def test_display_names    
    c = customers(:bob)
    assert_equal('Bob B.', c.display_name)
    assert_equal('Bob Voot', c.full_name)
  end

  # Test authentication
  def test_authentication    
    assert_equal(customers(:bob), Customer.authenticate('bob@bob.com', 'password'))
    assert_nil(Customer.authenticate('bob@bob.com', 'passworD'))
    assert_nil(Customer.authenticate('bobo@bob.com', 'password'))
  end

  # Make sure SSN validation works
  def test_ssn_validation    
    customer = Customer.new(:email => 'foo@smartflix.com', :first_name => 'Bob', :last_name => 'Smith',
                            :password => '12345', :password_confirmation => '12345')
    assert(customer.valid?)
    customer.ssn = '1'
    assert(!customer.valid?)
    customer.ssn = '123456789'
    assert(customer.valid?)
  end

  # Make sure SSN is stored encrypted only
  def test_ssn_storage    

    customer1 = customers(:bob)
    customer1.ssn = '987654321'

    # customer1 should have both unencrypted and encrypted ssn's:
    assert_not_nil(customer1.ssn)
    assert_not_nil(customer1.encrypted_ssn)
    # encrypted ssns contain alphabetic characters, unencrypted ssns do not:
    assert_match(/[a-zA-Z_\/=]+/, customer1.encrypted_ssn)
    # also, the encrypted and unencrypted ssn's should not be equal!
    assert_not_equal(customer1.ssn, customer1.encrypted_ssn)

    # update the database.
    customer1.save

    #Reading the data into a new instance of customer:
    customer2 = Customer.find(customer1.id)
    # the new instance should not have anything in the un-encrypted ssn field:
    assert_nil(customer2.ssn)
    # and the encrypted slot should match the value in customer1:
    assert_equal(customer2.encrypted_ssn, customer1.encrypted_ssn)

  end

  # Make sure affiliate transactions stuff works as expected
  def test_affiliate_transactions    

    aff_customer = customers(:bob)
    aff_customer.ssn = '987654321'
    aff_customer.save

    trans1 = AffiliateTransaction.create(:transaction_type => 'C',
                                         :affiliate_customer_id => aff_customer.id,
                                         :referred_customer_id => 1,
                                         :amount => 5.0,
                                         :date => Date.today)

    assert_equal(1, aff_customer.affiliate_transactions.size)
    assert_equal(0, aff_customer.affiliate_payment_transactions.size)
    assert_equal(5.0, aff_customer.affiliate_balance)

    trans2 = AffiliateTransaction.create(:transaction_type => 'C',
                                         :affiliate_customer_id => aff_customer.id,
                                         :referred_customer_id => 2,
                                         :amount => 5.0,
                                         :date => Date.today)

    # Reload, because transactions are cached
    aff_customer.reload

    assert_equal(2, aff_customer.affiliate_transactions.size)
    assert_equal(0, aff_customer.affiliate_payment_transactions.size)
    assert_equal(10.0, aff_customer.affiliate_balance)

    trans3 = AffiliateTransaction.create(:transaction_type => 'P',
                                         :affiliate_customer_id => aff_customer.id,
                                         :referred_customer_id => nil,
                                         :amount => -5.0,
                                         :date => Date.today)

    aff_customer.reload

    assert_equal(3, aff_customer.affiliate_transactions.size)
    assert_equal(1, aff_customer.affiliate_payment_transactions.size)
    assert_equal(5.0, aff_customer.affiliate_balance)
  end

  # Test crediting a customer account
  def test_credit    
    bob = customers(:bob)
    # Base state, nothing
    assert_equal(0.0, bob.credit)
    assert_nil(bob.account_credit)

    # subtract account credit from zero: doesn't count, doesn't throw
    bob.subtract_account_credit(0.0)
    assert_equal(0.0, bob.credit)

    begin
      bob.subtract_account_credit(1.0)
      assert false, "should have thrown"
    rescue
      assert true
    end
    assert_equal(0.0, bob.credit)

    assert_equal(0.0, bob.reload.credit)

    # Single basic credit
    bob.add_account_credit(10.0)
    assert_equal(10.0, bob.credit)
    assert_not_nil(bob.account_credit)
    assert_equal(1, bob.account_credit.account_credit_transactions.size)
    assert_equal('CashCredit', bob.account_credit.account_credit_transactions[0].transaction_type)
    assert_nil(bob.account_credit.account_credit_transactions[0].gift_certificate)
    # Second credit
    bob.add_account_credit(15.0)
    assert_equal(25.0, bob.credit)
    assert_not_nil(bob.account_credit)
    assert_equal(2, bob.account_credit.account_credit_transactions.size)
    # Debit!
    bob.add_account_credit(-3.0)
    assert_equal(22.0, bob.credit)
    assert_not_nil(bob.account_credit)
    assert_equal(3, bob.account_credit.account_credit_transactions.size)
    # Get fancy, use a gift certificate
    GiftCertificate.create(:code => 'haha', :amount => 22.00)
    gc = GiftCertificate.find_by_code('haha')
    assert(!gc.used?)
    bob.add_account_credit(gc)
    assert(gc.used?)
    assert_equal(44.00, bob.credit)
    assert_equal(4, bob.account_credit.account_credit_transactions.size)
    assert_equal(gc, bob.account_credit.account_credit_transactions[3].gift_certificate)
    assert_equal('GiftCertificate', bob.account_credit.account_credit_transactions[3].transaction_type)
    gc.reload
    assert_equal(bob, gc.account_credit_transaction.account_credit.customer)
    assert_equal(bob, gc.used_by_customer)
    # Make sure everything was saved ok
    bob.reload
    assert_equal(44.00, bob.credit)
    # Try to use the same gift certificate again
    gc = GiftCertificate.find_by_code('haha')
    bob.add_account_credit(gc)
    assert_equal(44.00, bob.credit)
    assert_equal(4, bob.account_credit.account_credit_transactions.size)
  end

  def test_has_rented    
    bob = customers(:bob)
    assert bob.has_rented?(1)
    assert !bob.has_rented?(8)
  end

  def test_has_reviewed    
    bob = customers(:bob)
    assert bob.has_reviewed?(1)
    assert !bob.has_reviewed?(8)
  end

  def test_postcheckout_upsell_recommend    

    customer = Customer.create!(:password => "password", :first_name => "first", :last_name => "last", :email=>"#{String.random_alphanumeric}@smartflix.com")
    cart = Cart.create!(:customer => customer)

    cat = Category.create!(:name => "foo", :description => "foo")

    products = []
    0.upto(10) do |x| 
      products[x] = Product.create!(:name => "product #{x}", 
                                    :description => "desc", 
                                    :date_added => Date.today,
                                    :display => true,
                                    :vendor_id => 1,
                                    :categories => [cat]) 
      cart.add_product(products[x], :save_for_later => true)
    end

    order_one = Order.create(:customer => customer)

    #====================
    # basic


    # first, verify that the reco algorithm returns items from the wishlist
    recos = customer.postcheckout_upsell_recommend(1, 2, order_one)
    assert_equal(recos[0], products[0])
    assert_equal(recos[1], products[1])

    # then verify that a second page works too 
    recos = customer.postcheckout_upsell_recommend(2, 2, order_one)
    assert_equal(recos[0], products[2])
    assert_equal(recos[1], products[3])


    # go back and make sure that the first page values haven't 
    recos = customer.postcheckout_upsell_recommend(1, 2, order_one)
    assert_equal(recos[0], products[0])
    assert_equal(recos[1], products[1])


    #====================
    # verify that on second checkout, new recos are given

    order_two = Order.create(:customer => customer)

    recos = customer.postcheckout_upsell_recommend(1, 2, order_two)
    assert_equal(recos[0], products[4], recos[0].inspect)
    assert_equal(recos[1], products[5], recos[1].inspect)

    #====================
    # yet another checkout, this one should trigger a university reco
    # ...and uni recos should be sorted to the forefront

    cat = Category.create!(:description => "welding")
    prod = Product.create!(:name => "welding DVD", :description => "desc", :date_added => Date.today,  :display => true, :vendor_id => 1, :categories => [cat]) 
    cat.products << prod
    univ = University.create!(:name => "welding univ", :category => cat)

    order_three = Order.create!(:customer => customer)

    order_three.line_items << LineItem.create!(:product => prod)

    recos = customer.postcheckout_upsell_recommend(1, 2, order_three)

    assert_equal(recos[0], univ)
    assert_equal(recos[1], products[6])

  end

  def test_in_last_chargeable_week?  
    Customer.destroy_all
    CreditCard.destroy_all
    Payment.destroy_all

    customer = Customer.create!(:password => "password", :first_name => "first", :last_name => "last", :email=>"#{String.random_alphanumeric}@smartflix.com")
    cc = CreditCard.test_card_good
    customer.credit_cards << cc
    customer.save

    # credit card expires a year from now - should not be in last chargeable anything
    assert_equal(false, customer.in_last_chargeable_week?)
    assert_equal(false, customer.in_last_chargeable_month?)

    # change the date to 2 weeks before expiration
    Date.force_today(CreditCard.test_card_good.expire_date - 14)
    assert_equal(false, customer.in_last_chargeable_week?)
    assert_equal(true, customer.in_last_chargeable_month?)
    Date.force_today(nil)

    # change the date to 3 days before expiration
    Date.force_today(CreditCard.test_card_good.expire_date - 3)
    assert_equal(true, customer.in_last_chargeable_week?)
    assert_equal(true, customer.in_last_chargeable_month?)
    Date.force_today(nil)

    #
    # do it all again with a 2nd card
    #

    cc_2 = CreditCard.test_card_good
    cc_2.update_attributes(:year => (cc_2.year + 1) )
    customer.credit_cards << cc_2
    customer.save

    # credit card expires a year from now - should not be in last chargeable anything
    assert_equal(false, customer.in_last_chargeable_week?)
    assert_equal(false, customer.in_last_chargeable_month?)

    # change the date to 2 weeks before expiration of first card
    Date.force_today(CreditCard.test_card_good.expire_date - 14)
    assert_equal(false, customer.in_last_chargeable_week?)
    assert_equal(false, customer.in_last_chargeable_month?)
    Date.force_today(nil)


    # change the date to 3 days before expiration
    Date.force_today(CreditCard.test_card_good.expire_date - 3)
    assert_equal(false, customer.in_last_chargeable_week?)
    assert_equal(false, customer.in_last_chargeable_month?)
    Date.force_today(nil)

    # change the date to 2 weeks before expiration of first card
    Date.force_today(cc_2.expire_date - 14)
    assert_equal(false, customer.in_last_chargeable_week?)
    assert_equal(true, customer.in_last_chargeable_month?)
    Date.force_today(nil)


    # change the date to 3 days before expiration
    Date.force_today(cc_2.expire_date - 3)
    assert_equal(true, customer.in_last_chargeable_week?)
    assert_equal(true, customer.in_last_chargeable_month?)
    Date.force_today(nil)


  end



  def test_valid_cards    
    assert_equal(1, customers(:cc_no_statuses_live).valid_cards.size)
    assert_equal(1, customers(:cc_no_statuses_live).valid_cards(true).size)

    assert_equal(0, customers(:cc_no_statuses_expired).valid_cards.size)
    assert_equal(1, customers(:cc_no_statuses_expired).valid_cards(true).size)

    assert_equal(0, customers(:cc_one_status_declined).valid_cards.size)
    assert_equal(0, customers(:cc_one_status_declined).valid_cards(true).size)

    assert_equal(0, customers(:cc_one_status_expired).valid_cards.size)
    assert_equal(1, customers(:cc_one_status_expired).valid_cards(true).size)

    assert_equal(1, customers(:cc_one_status_gateway).valid_cards.size)
    assert_equal(1, customers(:cc_one_status_gateway).valid_cards(true).size)

    assert_equal(0, customers(:cc_one_status_addrnomatch).valid_cards.size)
    assert_equal(0, customers(:cc_one_status_addrnomatch).valid_cards(true).size)

    assert_equal(0, customers(:cc_two_status_addrnomatch_expired).valid_cards.size)
    assert_equal(0, customers(:cc_two_status_addrnomatch_expired).valid_cards(true).size)
  end

  def test_next_to_expire_credit_card    

    # no credit cards
    cust = customers(:cust_with_cc_0)
    cc = cust.next_to_expire_credit_card
    assert(cc.nil?)

    # 1 credit card, and it's expired
    cust = customers(:cust_with_cc_1)
    cc = cust.next_to_expire_credit_card
    assert(cc.nil?)

    # 2 credit cards, one expired, one good
    cust = customers(:cust_with_cc_2)
    cc = cust.next_to_expire_credit_card
    assert(cc.month == 3 && cc.year == Date.today.year + 1 )

    # 3 credit cards, all good, in order
    puts "----------"
    cust = customers(:cust_with_cc_3)
    cc = cust.next_to_expire_credit_card
    assert(cc) 
    assert(cc.month == 3 && cc.year = 2016)
    puts "----------"

    # 3 credit cards, all good, in reverse order
    cust = customers(:cust_with_cc_3)
    cc = cust.next_to_expire_credit_card
    assert(cc.month == 3 && cc.year = 2016)

  end

  def test_shipped_in_last_month_for_univ 
    Customer.destroy_all
    LineItem.destroy_all
    Copy.destroy_all
    Product.destroy_all
    Payment.destroy_all
    University.destroy_all
    
    univ = University.create(:name => "wood", :category_id => 1)
    
    input =  { 

      # normal case
      :cust1 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 100,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 5, 
                           :complete => true, 
                           :successful => true,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :dateOut => (Date.today - 40), :dateBack => (Date.today - 20) },
                    {:name => "smart2", :dateOut => (Date.today - 40), :dateBack => (Date.today - 20) },
                    {:name => "smart3", :dateOut => (Date.today - 40), :dateBack => (Date.today - 20) },
                    {:name => "smart4", :dateOut => (Date.today - 2), :dateBack => nil }
                  ]
        },
      },

      # note that 4 things have been shipped in the last 30 days, but
      # only 1 thing has been shipped in the last "university month"
      #
      # ...we should get the latter
      :cust2 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 100,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today - 5, 
                           :complete => true, 
                           :successful => true,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :dateOut => (Date.today - 20), :dateBack => (Date.today - 10) },
                    {:name => "smart2", :dateOut => (Date.today - 20), :dateBack => (Date.today - 10) },
                    {:name => "smart3", :dateOut => (Date.today - 20), :dateBack => (Date.today - 10) },
                    {:name => "smart4", :dateOut => (Date.today - 2), :dateBack => nil }
                  ]
        },
      },

      # a bit trickier yet - university month starts today
      :cust3 => { :in_field => {},
        :sf_order => { :orderDate => Date.today - 100,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :payments => [ { :date=> Date.today, 
                           :complete => true, 
                           :successful => true,
                           :status => Payment::PAYMENT_STATUS_DEFERRED} ],
          :lis => [ {:name => "smart1", :dateOut => (Date.today - 2), :dateBack => (Date.today - 1) },
                    {:name => "smart2", :dateOut => (Date.today - 2), :dateBack => (Date.today - 1) },
                    {:name => "smart3", :dateOut => (Date.today - 2), :dateBack => (Date.today - 1) },
                    {:name => "smart4", :dateOut => (Date.today), :dateBack => nil },
                    {:name => "smart5", :dateOut => (Date.today), :dateBack => nil }
                  ]
        },
      },

    }
    build_fake(input)

    cust1 = txt2cust(:cust1)
    assert_equal( 1, cust1.shipped_in_last_month_for_univ_size(univ.id))

    cust2 = txt2cust(:cust2)
    assert_equal( 1, cust2.shipped_in_last_month_for_univ_size(univ.id))

    cust3 = txt2cust(:cust3)
    assert_equal( 2, cust3.shipped_in_last_month_for_univ_size(univ.id))

  end

end

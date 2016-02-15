require 'test_helper'

class LineItemTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

    US_YES     = 18
    US_NO      = 17
    CANADA_YES = US_YES + 14
    CANADA_NO  = US_NO + 14

    APO_YES = US_YES + 14
    APO_NO  = US_NO + 14



  def test_late_items_warnable
    Customer.destroy_all
    Order.destroy_all
    LineItem.destroy_all
    CreditCard.destroy_all

    input =  { 
      :canada_yes => {
        :order1 => {   :orderDate => Date.today - CANADA_YES,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - CANADA_YES }
                    ]
        }
      },
      :canada_no => {
        :order1 => {   :orderDate => Date.today - CANADA_NO,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - CANADA_NO }
                    ]
        }
      },

      :us_yes => {
        :order1 => {   :orderDate => Date.today - US_YES,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - US_YES }
                    ]
        }
      },
      :us_no => {
        :order1 => {   :orderDate => Date.today - US_NO,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - US_NO }
                    ]
        }
      },

      :apo_yes => {
        :order1 => {   :orderDate => Date.today - US_YES,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - US_YES }
                    ]
        }
      },
      :apo_no => {
        :order1 => {   :orderDate => Date.today - US_NO,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - US_NO }
                    ]
        }
      }
    }
                   
    build_fake(input)

    # find customers
    #
    cust_canada_yes = txt2cust(:canada_yes)
    cust_canada_no = txt2cust(:canada_no)
    cust_us_yes = txt2cust(:us_yes)
    cust_us_no = txt2cust(:us_no)

    cust_apo_yes = txt2cust(:apo_yes)
    cust_apo_no = txt2cust(:apo_no)

    # hack addrs 
    #
    [ cust_canada_yes, cust_canada_no ].each { |cust|

      addr = cust.shipping_address
      addr.country_id = 38 # Canada
      addr.save!
    }

    [ cust_apo_yes, cust_apo_no ].each { |cust|
      addr = cust.shipping_address
      addr.state = State.first # Canada
      addr.save!
    }


    # do calc
    #
    warnable = LineItem.late_items_warnable()

    # test results
    {
       cust_canada_yes => true,
       cust_canada_no =>  false,
       cust_us_yes =>     true,
       cust_us_no =>      false,
       cust_apo_yes =>     true,
       cust_apo_no =>      false
    }.each_pair  { |cust, expected|

      li = cust.line_items.first      

      result = warnable.include?(li)
      assert_equal(expected, result)
    }

  end

  def test_late_items_chargeable    
    Customer.destroy_all
    Order.destroy_all
    LineItem.destroy_all
    CreditCard.destroy_all

    wood_univ  = University.create(:name => "wood", :category_id => 1)

    input =  { 
      :cust_us_yes => {
        :order1 => { 
          :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },
      :cust_us_yes_longago_charge => {
        :order1 => {   
          :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },

      :cust_us_no_univ => {
        :order1 => {   :orderDate => Date.today - 100,
          :server_name => "wood",
          :univ_dvd_rate => 3,
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },
      :cust_us_no_bad_copy => {
        :order1 => {   :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },
      :cust_us_no_no_warn => {
        :order1 => {   :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },
      :cust_us_no_recent_warn => {
        :order1 => {   :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },
      :cust_us_no_recent_charge => {
        :order1 => {   :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      },
      :cust_us_no_lost => {
        :order1 => {   :orderDate => Date.today - 100,
          :server_name => "smartflix.com",
          :paid => true,
          :lis => [ {:name => "foo1",
                      :dateOut => Date.today - 100 }
                    ]
        }
      }


    }
                   
    build_fake(input)

    # find customers
    #
    cust_us_yes = txt2cust(:cust_us_yes)
    cust_us_yes_longago_charge = txt2cust(:cust_us_yes_longago_charge)
    cust_us_no_bad_copy = txt2cust(:cust_us_no_bad_copy)
    cust_us_no_no_warn = txt2cust(:cust_us_no_no_warn)
    cust_us_no_recent_warn = txt2cust(:cust_us_no_recent_warn)
    cust_us_no_recent_charge = txt2cust(:cust_us_no_recent_charge)
    cust_us_no_lost = txt2cust(:cust_us_no_lost)
    cust_us_no_univ = txt2cust(:cust_us_no_univ)

    # hack copies as bad
    #
    [ cust_us_no_bad_copy ].each { |cust|
      cust.line_items.first.copy.mark_as_scratched
    }

    # hack lis to give warning 
    #
    ( Customer.find(:all) - [ cust_us_no_no_warn ]).each { |cust|
      cust.line_items.first.update_attributes(:lateMsg1Sent => (Date.today - 20))
    }
    [ cust_us_no_recent_warn ].each { |cust|
      cust.line_items.first.update_attributes(:lateMsg1Sent => (Date.today - 4))
    }

    # hack lis to note  payments
    #
    { cust_us_no_recent_charge => 0,
      cust_us_yes_longago_charge => 50,
    }.each_pair { |cust, days_ago|
      Date.force_today(Date.today - days_ago)
      order = Order.note_late_charge(cust, cust.orders.first.line_items )
      order.payments <<  Payment.create!( :amount => 4.99,
                             :amount_as_new_revenue => 4.99,
                             :complete => 1,
                             :successful => 1,
                             :updated_at => Time.now(),
                             :payment_method => "magic",
                             :message => "magic",
                             :customer => cust)
      Date.force_today(nil)
    }

    # hack to note charge for lost DVD
    #
    [ cust_us_no_lost
    ].each { |cust|
      order = Order.note_lost_charge(cust, cust.orders.first.line_items )
      order.payments <<  Payment.create!( :amount => 34.99,
                             :amount_as_new_revenue => 34.99,
                             :complete => 1,
                             :successful => 1,
                             :updated_at => Time.now(),
                             :payment_method => "magic",
                             :message => "magic",
                             :customer => cust)
      cust.line_items.first.copy.mark_as_lost_by_cust_paid

      cust.reload
    }

    # do calc
    #
    chargeable = LineItem.late_items_chargeable()

    # test results
    [ 
     { :cust => cust_us_yes,         :name => "cust_us_yes",         :gold =>    true },
     { :cust => cust_us_yes_longago_charge,         :name => "cust_us_yes_longago_charge",         :gold =>    true },
     { :cust => cust_us_no_bad_copy, :name => "cust_us_no_bad_copy", :gold =>    false },
     { :cust => cust_us_no_no_warn, :name => "cust_us_no_no_warn", :gold =>    false },
     { :cust => cust_us_no_recent_warn, :name => "cust_us_no_no_warn", :gold =>    false },
     { :cust => cust_us_no_recent_charge, :name => "cust_us_no_recent_charge", :gold =>    false },
     { :cust => cust_us_no_lost, :name => "cust_us_no_lost", :gold =>    false },
     { :cust => cust_us_no_univ, :name => "cust_us_no_univ", :gold =>    false },
    ].each  { |hh|
     cust = hh[:cust]
     name = hh[:name]
     gold = hh[:gold]

      # puts "==== #{name} // #{cust.inspect}"

      cust.reload
      li = cust.line_items.first
      result = chargeable.include?(li)
     assert_equal(gold, result)
    }

  end  
  # Test marking a line item as "wrong copy sent"
  def test_wrong_copy_sent        

    copy1 = copies(:copy1)
    copy2 = copies(:copy2)

    # Set up test line item, and mark the copy as sent
    li = LineItem.create(:order_id => 1, :product_id => 1, :price => '9.99', :shipment_id => 1, :copy => copy1,
                         :wrongItemSent => false, :copy_id_intended => nil)
    li.copy.update_attributes(:inStock => false)

    # Tell the line item we sent the wrong copy
    li.wrong_copy_sent(copy2)

    # Make sure the right things happened
    li.reload

    assert_equal(li.copy, copy2)
    assert_equal(li.intended_copy, copies(:copy1))
    assert(li.wrongItemSent)
    assert(copies(:copy1).inStock?)
    assert(!copies(:copy2).inStock?)
    
  end

  def test_utility_functions        
    li = line_items(:utility_unshipped)
    assert_equal( Date.parse("2008-02-15"), li.dateOrdered.to_date)
    assert_equal( nil,                      li.dateCancelled)
    assert_equal( nil,                      li.dateOut)
    assert_equal( nil,                      li.dateBack)

    li = line_items(:utility_cancelled)
    assert_equal( Date.parse("2008-02-15"), li.dateOrdered.to_date)
    assert_equal( Date.parse("2008-02-20"), li.dateCancelled.to_date)
    assert_equal( nil,                      li.dateOut)
    assert_equal( nil,                      li.dateBack)

    li = line_items(:utility_infield)
    assert_equal( Date.parse("2008-02-15"), li.dateOrdered.to_date)
    assert_equal( nil,                      li.dateCancelled)
    assert_equal( Date.parse("2008-02-17"), li.dateOut)
    assert_equal( nil,                      li.dateBack)

    li = line_items(:utility_back)
    assert_equal( Date.parse("2008-02-15"), li.dateOrdered.to_date)
    assert_equal( nil,                      li.dateCancelled)
    assert_equal( Date.parse("2008-02-18"), li.dateOut)
    assert_equal( Date.parse("2008-02-20"), li.dateBack)

  end

  def test_second_tier_utility_funcs        
    li = line_items(:utility_unshipped)
    assert_equal( :not_existing, li.status_at("2008-01-01"))
    assert_equal( :not_shipped,  li.status_at("2008-02-15"))
    assert_equal( :not_shipped,  li.status_at("2008-03-15"))
    assert_equal( :not_shipped,  li.status_at("2010-03-15"))

    li = line_items(:utility_cancelled)
    assert_equal( :not_existing, li.status_at("2008-01-01"))
    assert_equal( :not_shipped,  li.status_at("2008-02-15"))
    assert_equal( :not_shipped,  li.status_at("2008-02-17"))
    assert_equal( :cancelled,    li.status_at("2008-02-22"))
    assert_equal( :cancelled,    li.status_at("2008-12-31"))

    li = line_items(:utility_infield)
    assert_equal( :not_existing, li.status_at("2008-01-01"))
    assert_equal( :not_shipped,  li.status_at("2008-02-16"))
    assert_equal( :in_field,     li.status_at("2008-02-17"))
    assert_equal( :in_field,     li.status_at("2008-12-31"))

    li = line_items(:utility_back)
    assert_equal( :not_existing, li.status_at("2008-01-01"))
    assert_equal( :not_shipped,  li.status_at("2008-02-16"))
    assert_equal( :in_field,     li.status_at("2008-02-19"))
    assert_equal( :back,         li.status_at("2008-02-20"))
    assert_equal( :back,         li.status_at("3128-12-30"))
  end

  def test_third_tier_utility_funcs        
    li = line_items(:utility_unshipped)
    assert_equal( false, li.live_at("2008-01-01"))
    assert_equal( true,  li.live_at("2008-02-15"))
    assert_equal( true,  li.live_at("2008-12-31"))

    li = line_items(:utility_cancelled)
# [:dateOrdered, :dateOut, :dateCancelled, :dateBack].each do |dd|
#       puts "#{dd} - #{li.send(dd)}"
# end
#     puts "XXX li #{li.live_at("2008-01-01")}"
    assert_equal( false, li.live_at("2008-01-01"))
    assert_equal( true,  li.live_at("2008-02-15"))
    assert_equal( true,  li.live_at("2008-02-19"))
    assert_equal( false, li.live_at("2008-02-20"))

    li = line_items(:utility_infield)
    assert_equal( false, li.live_at("2008-01-01"))
    assert_equal( true,  li.live_at("2008-02-15"))
    assert_equal( true,  li.live_at("2008-12-25"))

    li = line_items(:utility_back)
    assert_equal( false, li.live_at("2008-01-01"))
    assert_equal( true,  li.live_at("2008-02-15"))
    assert_equal( true,  li.live_at("2008-02-19"))
    assert_equal( false, li.live_at("2008-02-20"))
  end

end

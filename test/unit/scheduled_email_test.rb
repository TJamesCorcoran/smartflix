require 'test_helper'

class ScheduledEmailTest < ActiveSupport::TestCase

#   # Load up all the fixtures
#   fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
#   fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })


#   def test_relationships
#     assert_instance_of Customer, scheduled_emails(:one).customer
    
#     assert_instance_of Array, Customer.find(1).scheduled_emails
#     assert_instance_of ScheduledEmail, Customer.find(1).scheduled_emails[0]
#   end

#   def test_browsed_detect_and_note
#     cust = customers(:tyler)

#     product = products(:title1)
#     assert_equal([], cust.browsed_recommendations_sent)

    
#     ScheduledEmail.create(:customer => cust,
#                           :product => product,
#                           :email_type => "browsed")
#     cust.reload
#     assert_equal([product], cust.browsed_recommendations_sent)
#   end


#   def test_browsed_full
#     cust = customers(:travis)
#     product = products(:title1)

#     assert_equal([], cust.browsed_but_not_rented_or_recoed)

#     UrlTrack.create!(:session_id => "123",
#                      :customer_id => cust.id,
#                      :path => "/store/video/500/Title1",
#                      :controller => "store",
#                      :action => "video",
#                      :action_id => 500)


#     cust.reload
#     assert_equal([product], cust.browsed_but_not_rented_or_recoed)

#     sch =    ScheduledEmail.create!(:customer => cust,
#                           :product => product,
#                           :email_type => "browsed")

#     cust.reload

#     assert_equal([], cust.browsed_but_not_rented_or_recoed)

#     assert_equal(sch.product, product)
#   end

  def test_recover_old
    Order.destroy_all

    univ = University.create!(:name => "wood-u")

    data =  { 
      :cust1 => { 
        :in_field => { "wood-u"    => 0},
        :order1 => {   
          :orderDate => (Date.today - 365),
          :server_name => "wood-u",
          :univ_dvd_rate => 3,
          :lis => [],
          :paid => false,
          :live => false
        }
      }
    }
    
    build_fake(data)
    
    cust  = txt2cust("cust1")
    order = cust.univ_orders.first
    
    assert_equal(1, cust.univ_orders.size)
    assert_equal(:cancelled_full, order.univ_status)
    
    @emails = ActionMailer::Base.deliveries
    @emails.clear

    ScheduledEmailer.recover_cancelled_univ_custs

    assert_equal( 1, @emails.size)
    
  end

end

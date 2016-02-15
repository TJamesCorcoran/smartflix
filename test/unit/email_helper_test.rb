require 'test_helper'

class EmailHelperTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def test_image_helpers    
    email_helper_obj = ActionView::Base.new
	email_helper_obj.extend EmailHelper
    email_helper_obj.controller = CartController.new

    # test for product
	actual = email_helper_obj.email_image_for(Product.find(1), {} )
    gold = "<img alt=\"Product1 by Arthur Author\" border=\"0\" src=\"http://smartflix.com/vidcaps/svidcap_1.jpg\" title=\"Product1 by Arthur Author\" />"
    assert_equal( gold, actual)


    # test for project
	actual = email_helper_obj.email_image_for(Project.find(1), {} )
    gold = "<img alt=\"my project #1 by Bob B.\" border=\"0\" src=\"/images/.*\" title=\"my project #1 by Bob B.\" />"
    assert( actual.match(gold), "actual #{actual} != gold #{gold}")
  end

  def test_email_image_for  
    eh = ActionView::Base.new
	eh.extend EmailHelper

    tt = products(:title1)

    gold = '<img alt="Title1 by FooBar" border="0" src="http://smartflix.com/vidcaps/svidcap_500.jpg" title="Title1 by FooBar" />'
	actual = eh.email_image_for( tt, {} )
    assert_equal(gold, actual)
  end

  def test_email_add_to_cart_button
    eh = ActionView::Base.new
	eh.extend EmailHelper

    # button for a video
    #
    tt = products(:title1)
    gold = '<a href="http://smartflix.com/cart/add/500?token=TTTTT&ct=CCCCC"><img alt="Rent video: Title1 by FooBar" border="0" src="http://smartflix.com/images/rent_buttons/rent_now_b.gif" style="margin-top:5px; margin-bottom:40px;" title="Rent video: Title1 by FooBar" /></a>'
    actual = eh.email_add_to_cart_button(tt, "TTTTT", { :ctcode => "CCCCC"})
    assert_equal(gold, actual)

    # button for a UnivStub
    #
    tt = products(:tobuy_title_univstub)
    gold = '<a href="http://smartflix.com/cart/add/2001?token=TTTTT&ct=CCCCC"><img alt="Subscribe to foo univ" border="0" src="http://smartflix.com/images/buttons/big_subscribe.jpg" style="margin-top:5px; margin-bottom:40px;" title="Subscribe to foo univ" /></a>'
    actual = eh.email_add_to_cart_button(tt, "TTTTT", { :ctcode => "CCCCC"})
    assert_equal(gold, actual)

  end

end

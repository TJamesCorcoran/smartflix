require 'test_helper'

class PromotionTest < ActiveSupport::TestCase
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  
  def test_find_all_for_audience_true
    #assert_equal [1,2], Promotion.find_all_for_audience( true ).map{|p| p.id}
  end
  
  def test_find_all_for_audience_false
    #assert_equal [1,3], Promotion.find_all_for_audience( false ).map{|p| p.id}
  end
  
  def ordered_pages
    #assert_equal [2,1], Promotion.find(1).ordered_pages.map{|pp| pp.id}
  end
  
  def minimized_content
    #Promotion.find(1).minimized_content == Promotion.find(1).tagline
  end
  
  def for_audience
    #assert Promotion.find(1).for_audience?(true)
    #assert Promotion.find(1).for_audience?(false)
    
    #assert Promotion.find(2).for_audience?(true)
    #assert !Promotion.find(2).for_audience?(false)
    
    #assert !Promotion.find(3).for_audience?(true)
    #assert Promotion.find(3).for_audience?(false)
  end
end

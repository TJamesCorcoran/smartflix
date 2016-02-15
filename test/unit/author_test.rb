require 'test_helper'

class AuthorTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # Make sure we can get the listable products for an author
  def test_listable_1
    a = authors(:author1)
    l = a.listable_products()
    assert_equal(1, l.size)
    assert_equal(products(:product1), l[0])
  end

  # Same test, but throw in some with display = false and sets, etc
  def test_listable_2
    a = authors(:author2)
    l = a.listable_products()
    assert_equal(4, l.size)
    assert_equal(products(:product2), l[0])
    assert_equal(products(:product3), l[1])
    assert_equal(products(:product5), l[2])
  end

end



require 'test_helper'

class CategoryTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # Make sure listable products are correctly created
  def test_listable
    assert_equal(0, categories(:category1).listable_products.size)
    assert_equal(2, categories(:category2).listable_products.size)
    assert_equal(products(:product1), categories(:category2).listable_products[0])
    assert_equal(products(:product2), categories(:category2).listable_products[1])
    assert_equal(2, categories(:category3).listable_products.size)
    assert_equal(products(:product3), categories(:category3).listable_products[0])
    assert_equal(products(:product5), categories(:category3).listable_products[1])
  end

  # Make sure toplevel is correctly identified
  def test_toplevel
    assert(categories(:category1).toplevel?)
    assert(!categories(:category2).toplevel?)
    assert(!categories(:category3).toplevel?)
  end

  # Make sure full category path is correct
  def test_path
    assert_equal(1, categories(:category1).full_path.size)
    assert_equal(categories(:category1), categories(:category1).full_path[0])
    assert_equal(2, categories(:category2).full_path.size)
    assert_equal(categories(:category1), categories(:category2).full_path[0])
    assert_equal(categories(:category2), categories(:category2).full_path[1])
    assert_equal(2, categories(:category3).full_path.size)
    assert_equal(categories(:category1), categories(:category3).full_path[0])
    assert_equal(categories(:category3), categories(:category3).full_path[1])
  end

  # Make sure the display listing gets set up correctly
  def test_display_list

    # Nothing selected
    list = Category.display_list
    assert_equal(1, list.size)
    assert_equal(categories(:category1), list[0])

    # Non-leaf selected
    list = Category.display_list(categories(:category1))
    assert_equal(6, list.size, list.inspect)
    assert_equal(categories(:category1), list[0])
    assert_equal(categories(:category2), list[1])
    assert_equal(categories(:category3), list[2])
    assert(list[0].selected)
    assert(!list[1].selected)
    assert(!list[2].selected)
    assert(!list[0].indented)
    assert(list[1].indented)
    assert(list[2].indented)    

    # Leaf selected
    list = Category.display_list(categories(:category3))
    assert_equal(6, list.size)
    assert_equal(categories(:category1), list[0])
    assert_equal(categories(:category2), list[1])
    assert_equal(categories(:category3), list[2])
    assert(!list[0].selected)
    assert(!list[1].selected)
    assert(list[2].selected)
    assert(!list[0].indented)
    assert(list[1].indented)
    assert(list[2].indented)

  end

end

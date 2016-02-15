# XXXFIX P3: Test interaction of display=false with cart

require 'test_helper'
include ERB::Util
include ApplicationHelper
include CartHelper



# mocks
def image_submit_tag(a,b) "submit tag" end
def form_tag(options = { }) "form tag" end
def hidden_field_tag(a,b) "hidden_field_tag" end
def link_to(a,b,c)  "link"end


@@ab_test_hash = { }
def ab_test_set(test_name, value) 
  @@ab_test_hash[test_name] = value 
end
def ab_test(test_name)  
  @@ab_test_hash[test_name]
end


class CartTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # Test adding single videos, making sure that count and price are correct
  def test_add_product
    cart = Cart.new
    cart.add_product(Product.find(1))
    assert_equal(1, cart.cart_items.size)
    cart.add_product(Product.find(2))
    assert_equal(2, cart.cart_items.size)
    assert_equal(BigDecimal('19.98'), cart.total)
  end

  # Test the "add_products" method, adding an array of products to the
  # cart.  Used by add_set, add_bundle and now directly from
  # cart_controller.rb add_to_cart_common in support of the "Rent this
  # together with that" feature.
  def test_add_products
    cart = Cart.new
    cart.add_products([Product.find(1), Product.find(2)])
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(BigDecimal('19.98'), cart.total)
    cart.add_products([Product.find(1), Product.find(2)])
    assert_equal(2, cart.items_to_buy.size)
    cart.add_products([Product.find(1), Product.find(2)], :save_for_later => true)
    assert_equal(0, cart.items_to_buy.size)
    cart.toggle_saved_for_later(Product.find(2))
    assert_equal(1, cart.items_to_buy.size)
    cart.add_products([Product.find(1), Product.find(2)])
    assert_equal(2, cart.items_to_buy.size)    
    assert_raise(DuplicateItem) { cart.add_product(Product.find(1)) }
  end


  # Test deleting single videos, making sure that count and price are correct
  def test_delete_product
    cart = Cart.new
    cart.add_product(Product.find(1))
    cart.add_product(Product.find(2))
    cart.delete_product(Product.find(1))
    assert_equal(1, cart.cart_items.size)
    assert_equal(BigDecimal('9.99'), cart.total)
    cart.delete_product(Product.find(1))
    assert_equal(1, cart.cart_items.size)
    assert_equal(BigDecimal('9.99'), cart.total)
    cart.delete_product(Product.find(2))
    assert(cart.empty?)
    assert_equal(0, cart.cart_items.size)
    assert_equal(BigDecimal('0.00'), cart.total)
  end

  # Test adding a video that's already in the cart
  def test_add_duplicate
    cart = Cart.new
    cart.add_product(Product.find(1))
    assert_raise(DuplicateItem) { cart.add_product(Product.find(1)) }
    assert_equal(1, cart.cart_items.size)
    assert_equal(BigDecimal('9.99'), cart.total)
  end

  # Test getting a set of videos by adding them one at a time
  def test_add_set_as_singles
    cart = Cart.new
    cart.add_product(products(:product4))
    assert_equal(1, cart.cart_items.size)
    assert_equal(BigDecimal('14.99'), cart.total)
    cart.add_product(products(:product5))
    assert_equal(2, cart.cart_items.size)
    assert_equal(BigDecimal('23.98'), cart.total)
  end

  # Test adding a set of videos
  def test_add_set
    cart = Cart.new
    cart.add_set(product_sets(:product_set1))
    assert_equal(2, cart.cart_items.size)
    assert_equal(BigDecimal('23.98'), cart.total)
  end

  # Test adding a set of videos when there's already one of the videos present
  def test_add_set_duplicate
    cart = Cart.new
    cart.add_product(products(:product4))
    assert_equal(1, cart.cart_items.size)
    assert_equal(BigDecimal('14.99'), cart.total)
    cart.add_set(product_sets(:product_set1))
    assert_equal(2, cart.cart_items.size)
    assert_equal(BigDecimal('23.98'), cart.total)
  end

  # Test adding a single video when the set is already present
  def test_add_single_duplicate_of_set
    cart = Cart.new
    cart.add_set(product_sets(:product_set1))
    assert_raise(DuplicateItem) { cart.add_product(products(:product4)) }
    assert_equal(2, cart.cart_items.size)
    assert_equal(BigDecimal('23.98'), cart.total)
  end

  # Test adding a set and removing one element, make sure non-set pricing
  def test_add_set_remove_one
    cart = Cart.new
    cart.add_set(product_sets(:product_set1))
    cart.delete_product(products(:product4))
    assert_equal(1, cart.cart_items.size)
    assert_equal(products(:product5), cart.cart_items[0].product)
    assert_equal(BigDecimal('14.99'), cart.total)
  end

  # Test save-for-later functionality
  def test_save_for_later

    cart = Cart.new
    cart.add_product(Product.find(1))
    cart.add_product(Product.find(2))
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(0, cart.items_saved.size)
    assert_equal(BigDecimal('19.98'), cart.total)

    # Toggle product 2 into saved
    cart.toggle_saved_for_later(Product.find(2))
    assert_equal(1, cart.items_to_buy.size)
    assert_equal(1, cart.items_saved.size)
    assert_equal(BigDecimal('9.99'), cart.total)

    # Toggle product 2 back
    cart.toggle_saved_for_later(Product.find(2))
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(0, cart.items_saved.size)
    assert_equal(BigDecimal('19.98'), cart.total)

    # Toggle a product that's not in the cart (no-op)
    cart.toggle_saved_for_later(Product.find(3))
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(0, cart.items_saved.size)
    assert_equal(BigDecimal('19.98'), cart.total)

    # Toggle both
    cart.toggle_saved_for_later(Product.find(1))
    cart.toggle_saved_for_later(Product.find(2))
    assert_equal(0, cart.items_to_buy.size)
    assert_equal(2, cart.items_saved.size)
    assert_equal(BigDecimal('0.00'), cart.total)
    
  end

  # now (due to ABTEST of "wishlist" buttons), Cart instance method
  # "add_product" takes an additional options parameter which allows
  # caller to specify whether to add the item to the "to buy" portion
  # of the cart or the "saved for later/wishlist" portion.  This test
  # exercises that functionality.  Defaults to "not saved". --nzc Fri
  # Feb 15 11:36:12 2008
  def test_add_product_with_save

    # throw a couple of products into the cart in the "saved" state,
    # check results:
    cart = Cart.new
    cart.add_product(Product.find(1), :save_for_later => true)
    cart.add_product(Product.find(2), :save_for_later => true)
    assert_equal(2, cart.items_saved.size)
    assert_equal(0, cart.items_to_buy.size)
    assert_equal(BigDecimal('0.0'), cart.total)

    cart.toggle_saved_for_later(Product.find(1))
    assert_equal(1, cart.items_saved.size)
    assert_equal(1, cart.items_to_buy.size)
    assert_equal(BigDecimal('9.99'), cart.total)
    
    cart.toggle_saved_for_later(Product.find(1))
    assert_equal(2, cart.items_saved.size)
    assert_equal(0, cart.items_to_buy.size)
    assert_equal(BigDecimal('0.0'), cart.total)
    
    # move both of the saved products to "to buy", check results    
    cart.toggle_saved_for_later(Product.find(1))
    cart.toggle_saved_for_later(Product.find(2))
    assert_equal(0, cart.items_saved.size)
    assert_equal(2, cart.items_to_buy.size)
    assert_equal(BigDecimal('19.98'), cart.total)
    
  end

  # Test removal of all the to-buy items
  def test_remove_items_to_buy
    cart = Cart.new
    cart.add_product(Product.find(1))
    cart.add_product(Product.find(2))
    cart.add_product(Product.find(3))
    cart.toggle_saved_for_later(Product.find(3))
    cart.empty_to_buy()
    assert_equal(0, cart.items_to_buy.size)
    assert_equal(1, cart.items_saved.size)
    assert_equal(BigDecimal('0.0'), cart.total)
    cart.toggle_saved_for_later(Product.find(3))
    assert_equal(1, cart.items_to_buy.size)
    assert_equal(0, cart.items_saved.size)
    assert_equal(BigDecimal('14.99'), cart.total)
    cart.empty_to_buy()
    assert_equal(0, cart.cart_items.size)
  end

  # Test the merging of two carts
  def test_merge

    # Simple merge
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(2))
    cart1.merge(cart2)
    assert_equal(2, cart1.cart_items.size)

    # Simple merge, with dups
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(1))
    cart1.merge(cart2)
    assert_equal(1, cart1.cart_items.size)

    # Slightly more complicated, one new and one dup
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(1))
    cart2.add_product(Product.find(2))
    cart1.merge(cart2)
    assert_equal(2, cart1.cart_items.size)

    # Make sure saved-for-later items are merged nicely
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(2))
    cart2.toggle_saved_for_later(Product.find(2))
    cart1.merge(cart2)
    assert_equal(1, cart1.items_saved.size)
    assert_equal(1, cart1.items_to_buy.size)
    assert_equal(1, cart1.items_to_buy[0].product.id)
    assert_equal(2, cart1.items_saved[0].product.id)

    # Make sure saved-for-later items are handled correctly if different
    # in each cart (the source cart of the merge should decide)
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(1))
    cart2.toggle_saved_for_later(Product.find(1))
    cart1.merge(cart2)
    assert_equal(1, cart1.items_saved.size)
    assert_equal(0, cart1.items_to_buy.size)
    
    # Reverse from above
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(1))
    cart1.toggle_saved_for_later(Product.find(1))
    cart1.merge(cart2)
    assert_equal(0, cart1.items_saved.size)
    assert_equal(1, cart1.items_to_buy.size)

    # Make sure option to "merge saved items only" works as expected
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart2.add_product(Product.find(2))
    cart2.add_product(Product.find(3))
    cart2.toggle_saved_for_later(Product.find(3))
    cart1.merge(cart2, :saved_items_only => true)
    assert_equal(1, cart1.items_to_buy.size)
    assert_equal(1, cart1.items_saved.size)
    assert_equal(1, cart1.items_to_buy[0].product.id)
    assert_equal(3, cart1.items_saved[0].product.id)

  end

  # Test the subtraction of one cart from another (only the to-buy items
  # get subtracted)
  def test_subtract
    cart1 = Cart.new
    cart2 = Cart.new
    cart1.add_product(Product.find(1))
    cart1.add_product(Product.find(2))
    cart2.add_product(Product.find(1))
    cart2.add_product(Product.find(2))
    cart2.add_product(Product.find(3))
    cart2.toggle_saved_for_later(Product.find(2))
    cart1.subtract(cart2)
    assert_equal(1, cart1.cart_items.size)
    assert_equal(2, cart1.cart_items[0].product.id)
  end

  # Test getting recommended products based on cart
  # def test_recommended
  #   cart1 = Cart.new
  #   assert_equal(0, cart1.recommended_products.size)
  #   cart1.add_product(Product.find(1))
  #   assert_equal(1, cart1.recommended_products.size)
  #   assert_equal(1, cart1.recommended_products(:limit => 1).size)
  #   assert_equal(5, cart1.recommended_products[0].id)
  #   assert_equal(3, cart1.recommended_products[1].id)
  # end

  def test_helper
    cart = Cart.new
    cart.add_product(Product.find(1))
    
    [:items_to_buy, :items_saved].each do |method|
      [:summary, :full].each do |style|
        [true, false].each do |display_total|
          [true, false].each do |ab_show_purchase_price_basket|
            ab_test_set(:show_purchase_price_basket, ab_show_purchase_price_basket)
            CartHelper.cart_display_for(cart, method, { :style => style, :display_total => display_total })
            # just test that we don't blow up
            assert(true)
          end
        end
      end
    end

  end
  
  
end

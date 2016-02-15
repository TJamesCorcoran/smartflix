require 'test_helper'
class CartGroupTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # XXXFI P1: Add test for set with 1 member not displayed

  # Make sure that singleton videos and sets group correctly
  def test_grouping

    i1 = CartItem.create(:product_id => 1)
    i2 = CartItem.create(:product_id => 4)
    i3 = CartItem.create(:product_id => 5)

    groups = CartGroup.groups_for_items([i1, i2, i3])

    assert_equal(2, groups.size)

    assert_equal(1, groups[0].size)
    assert_equal(1, groups[0][0].product_id)
    assert(!groups[0].set_discount?)
    assert_equal(BigDecimal('9.99'), groups[0].total)
    assert_equal(BigDecimal('0.00'), groups[0].savings)
    groups[0].items_with_prices { |item, price| assert_equal(BigDecimal('9.99'), price) }

    assert_equal(2, groups[1].size)
    assert_equal(4, groups[1][0].product_id)
    assert_equal(5, groups[1][1].product_id)
    assert_equal(5, groups[1].sorted_items[0].product_id)
    assert_equal(4, groups[1].sorted_items[1].product_id)
    assert(groups[1].set_discount?)
    assert_equal(BigDecimal('23.98'), groups[1].total)
    assert_equal(ApplicationHelper.round_currency(BigDecimal('6.00')), ApplicationHelper.round_currency(groups[1].savings))
    groups[1].items_with_prices do |item, price|
      assert_equal(BigDecimal('0.00'), price) if item.product.id == 5
      assert_equal(BigDecimal('23.98'), price) if item.product.id == 4
    end

  end

  # Make sure a partial set is priced and bundled right
  def test_grouping_partial_set

    i = CartItem.for_product(Product.find(5))
    i.save

    groups = CartGroup.groups_for_items([i])

    assert_equal(1, groups.size)

    assert_equal(1, groups[0].size)
    assert_equal(5, groups[0][0].product_id)
    assert(!groups[0].set_discount?)
    assert_equal(BigDecimal('14.99'), groups[0].total)
    assert_equal(BigDecimal('0.00'), groups[0].savings)
    groups[0].items_with_prices { |item, price| assert_equal(BigDecimal('14.99'), price) }

  end

  # Make sure bundles group correctly
  def test_grouping_bundle

    i1 = CartItem.create(:product_id => 1)
    i2 = CartItem.create(:product_id => 2)
    i3 = CartItem.create(:product_id => 4)
    i4 = CartItem.create(:product_id => 5)

    groups = CartGroup.groups_for_items([i1, i2, i3, i4])

    assert_equal(2, groups.size)

    assert_equal(1, groups[0].size)
    assert_equal(1, groups[0][0].product_id)

    assert_equal(3, groups[1].size)
    assert_equal(2, groups[1][0].product_id)
    assert_equal(4, groups[1][1].product_id)
    assert_equal(5, groups[1][2].product_id)
    assert(groups[1].bundle_discount?)
    assert(!groups[1].set_discount?)
    assert_equal(ApplicationHelper.round_currency(BigDecimal('31.98')), ApplicationHelper.round_currency(groups[1].total))
    assert_equal(ApplicationHelper.round_currency(BigDecimal('7.99')), ApplicationHelper.round_currency(groups[1].savings))
    groups[1].items_with_prices do |item, price|
      assert_equal(BigDecimal('0.00'), price) if item.product.id == 2
      assert_equal(BigDecimal('0.00'), price) if item.product.id == 5
      assert_equal(BigDecimal('31.98'), price) if item.product.id == 4
    end

  end

  # Make sure bundles group correctly when there are multiple possible bundles
  def test_grouping_bundle_multiple

    i1 = CartItem.create(:product_id => 3)
    i2 = CartItem.create(:product_id => 2)
    i3 = CartItem.create(:product_id => 4)
    i4 = CartItem.create(:product_id => 5)

    groups = CartGroup.groups_for_items([i1, i2, i3, i4])

    assert_equal(1, groups.size)

    assert_equal(4, groups[0].size)
    assert_equal(3, groups[0][0].product_id)
    assert_equal(2, groups[0][1].product_id)
    assert_equal(4, groups[0][2].product_id)
    assert_equal(5, groups[0][3].product_id)
    assert_equal(3, groups[0].sorted_items[0].product_id)
    assert_equal(2, groups[0].sorted_items[1].product_id)
    assert_equal(5, groups[0].sorted_items[2].product_id)
    assert_equal(4, groups[0].sorted_items[3].product_id)
    assert(groups[0].bundle_discount?)
    assert(!groups[0].set_discount?)
    assert_equal(BigDecimal('43.97'), groups[0].total)
    assert_equal(ApplicationHelper.round_currency(BigDecimal('10.99')), ApplicationHelper.round_currency(groups[0].savings))
    groups[0].items_with_prices do |item, price|
      assert_equal(BigDecimal('0.00'), price) if item.product.id == 2
      assert_equal(BigDecimal('0.00'), price) if item.product.id == 3
      assert_equal(BigDecimal('0.00'), price) if item.product.id == 5
      assert_equal(BigDecimal('43.97'), price) if item.product.id == 4
    end

  end

end

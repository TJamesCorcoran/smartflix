class AbTestShowingDiscountOverPurchase < ActiveRecord::Migration
  def self.up
    add_column :products, :purchase_price,          :decimal, :precision => 6, :scale => 2, :default => '0.00'
    AbTester.create_test(:show_purchase_price_product, 6, 0.0, [:true, :false])
    AbTester.create_test(:show_purchase_price_basket,  6, 0.0, [:true, :false])
    AbTester.create_test(:show_discount_banner_frontpage,   6, 0.0, [:true, :false])
    AbTester.create_test(:show_discount_banner_category,    6, 0.0, [:true, :false])
    AbTester.create_test(:show_discount_banner_product,     6, 0.0, [:true, :false])
  end

  def self.down
    remove_column :products, :purchase_price
    AbTest.find_by_name("ShowPurchasePriceProduct").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("ShowPurchasePriceBasket").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("ShowDiscountBannerFrontpage").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("ShowDiscountBannerCategory").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("ShowDiscountBannerProduct").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

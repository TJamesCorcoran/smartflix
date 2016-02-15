class AbTestShowingDiscountOverPurchaseV2 < ActiveRecord::Migration
  def self.up
    # destroy the first attempt
    #
    AbTest.find_by_name("ShowPurchasePriceProduct").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("ShowPurchasePriceBasket").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])

    # do a second attempt, where :false is the first option and true is second
    #
    AbTester.create_test(:show_purchase_price_product, 7, 0.0, [:false, :true])
    AbTester.create_test(:show_purchase_price_basket,  7, 0.0, [:false, :true])
  end

  def self.down
    AbTest.find_by_name("ShowPurchasePriceProduct").destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("ShowPurchasePriceBasket").destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

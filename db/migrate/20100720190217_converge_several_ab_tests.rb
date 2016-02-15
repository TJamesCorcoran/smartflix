class ConvergeSeveralAbTests < ActiveRecord::Migration
  def self.up
    AbTester.deactivate_test("UnivFirstMonthDeal")
    AbTester.deactivate_test("ShowPurchasePriceBasket")
    AbTester.deactivate_test("MoneybackV2")
    AbTester.deactivate_test("PostcheckoutUpsell")
    AbTester.deactivate_test("UnivsInSearchResults")
    AbTester.deactivate_test("BigCheckoutButton")
    AbTester.deactivate_test("GuaranteeAlwaysInCart")
  end

  def self.down
    AbTester.reactivate_test("UnivFirstMonthDeal")
    AbTester.reactivate_test("ShowPurchasePriceBasket")
    AbTester.reactivate_test("MoneybackV2")
    AbTester.reactivate_test("PostcheckoutUpsell")
    AbTester.reactivate_test("UnivsInSearchResults")
    AbTester.reactivate_test("BigCheckoutButton")
    AbTester.reactivate_test("GuaranteeAlwaysInCart")
  end
end

class AbTestLinkToUnivsOnLeft < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:link_to_univs_on_left,  8, 0.0, [:false, :true])
    AbTester.create_test(:univ_button_tryit_or_quit,  8, 0.0, [:false, :true])
    AbTester.create_test(:guarantee_always_in_cart,  8, 0.0, [:false, :true])
    AbTester.create_test(:checkout_button_at_right,  8, 0.0, [:false, :true])
    AbTester.create_test(:big_checkout_button,  8, 0.0, [:false, :true])
  end

  def self.down
    AbTest.find_by_name("LinkToUnivsOnLeft").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("UnivButtonTryitOrQuit").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("GuaranteeAlwaysInCart").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("CheckoutButtonAtRight").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    AbTest.find_by_name("BigCheckoutButton").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

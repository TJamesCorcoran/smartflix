class UpdateSeveralAbtests < ActiveRecord::Migration
  def self.up
    # $0 was the win
    AbTest.find_by_name("FunnelDiscounts").update_attributes(:active => false)

    # restart, bc of change in funnel discount
    AbTest.find_by_name("FunnelFrontpage").update_attributes(:active => false)
    AbTester.create_test(:funnel_frontpage_two, 6, 0.0, [:false, :true])

    # restart, bc of change in funnel discount
    AbTest.find_by_name("FunnelVideopage").update_attributes(:active => false)
    AbTester.create_test(:funnel_videopage_two, 6, 0.0, [:false, :true])

    # no was the win
    AbTest.find_by_name("FunnelCatpage").update_attributes(:active => false)

    # no discount banner was the win
    AbTest.find_by_name("ShowDiscountBannerFrontpage").update_attributes(:active => false)

    # yes, banner was the win
    AbTest.find_by_name("ShowDiscountBannerCategory").update_attributes(:active => false)

    # restart, coded wrong - we were getting credit for postcheckout_upsell sales.  :(
    AbTest.find_by_name("ShowDiscountBannerProduct").update_attributes(:active => false)
    AbTester.create_test(:show_discount_banner_product_two, 6, 0.0, [:false, :true])

    # yes, win
    AbTest.find_by_name("ShowPurchasePriceProduct").update_attributes(:active => false)

    # yes, win
    AbTest.find_by_name("ShowRecentlyViewedBox").update_attributes(:active => false)

    # leave running:
    #
    # ShowPurchasePriceProduct
    
  end

  def self.down

    AbTest.find_by_name("FunnelDiscounts").update_attributes(:active => true)

    AbTest.find_by_name("FunnelFrontpage").update_attributes(:active => true)
    AbTest.find_by_name("Funnel_Frontpage_two").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])

    AbTest.find_by_name("FunnelVideopage").update_attributes(:active => true)
    AbTest.find_by_name("Funnel_Videopage_two").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])

    AbTest.find_by_name("FunnelCatpage").update_attributes(:active => true)

    AbTest.find_by_name("ShowDiscountBannerFrontpage").update_attributes(:active => true)

    AbTest.find_by_name("ShowDiscountBannerCategory").update_attributes(:active => true)

    AbTest.find_by_name("ShowDiscountBannerProduct").update_attributes(:active => true)
    AbTest.find_by_name("ShowDiscountBannerProductTwo").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])

    AbTest.find_by_name("ShowPurchasePriceProduct").update_attributes(:active => true)

    AbTest.find_by_name("ShowRecentlyViewedBox").update_attributes(:active => true)

  end
end

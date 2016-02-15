class MoneybackBannerV2 < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:moneyback_v2, 6, 0.0, [:false, :true])
    Promotion.create_new(:name => "moneyback_v2",
                         :display_for_which_urls_regexp => ".*", 
                         :minimize_text => "",
                         :ab_test_name => nil, 
                         :pages => { 1 => "<h1>120% Moneyback Guarantee</h1>
When you rent at SmartFlix, you've got our our no-questions-asked,
120%-money-back, 60-day guarantee: if you can't honestly say that the
DVDs you rent from SmartFlix gave you the skills you need, we will
return one hundred and twenty percent of your money, promptly and
courteously. It's the Smartflix Way!" })
  end

  def self.down
    AbTester.destroy_test("moneyback_v2")
    Promotion.find_by_tagline("moneyback_v2").destroy_self_and_children([:promotion_pages])
  end
end

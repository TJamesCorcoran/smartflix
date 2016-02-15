class CleanupAbUnivChoices < ActiveRecord::Migration
  
  def self.up
    AbTest.find_by_name("FirstMonthFree").update_attributes(:active => false)
    AbTest.find_by_name("FirstMonthUnivDiscount").update_attributes(:active => false)

    AbTester.create_test(:univ_first_month_deal, 6, 0.0, [:none, :fifty_percent, :free])
  end
  
  def self.down
    AbTest.find_by_name("FirstMonthFree").update_attributes(:active => true)
    AbTest.find_by_name("FrontpageUnivStubs").update_attributes(:active => true)

    AbTester.destroy_test(:univ_first_month_deal)
  end
end

class FirstMonthUnivDiscount < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:first_month_univ_discount,   6, 0.0, [:false, :true])
  end

  def self.down
    AbTest.find_by_name("FirstMonthUnivDiscount").destroy_self_and_children([:ab_test_options, :ab_test_results])
  end
end

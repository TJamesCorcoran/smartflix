class Add2011PriceIncrease < ActiveRecord::Migration
  def self.up
    University.all.each { |u| u.update_attributes(:subscription_charge => u.subscription_charge + 2.00) }
  end

  def self.down
    University.all.each { |u| u.update_attributes(:subscription_charge => u.subscription_charge - 2.00) }
  end
end

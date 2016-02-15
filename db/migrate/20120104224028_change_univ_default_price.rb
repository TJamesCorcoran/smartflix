class ChangeUnivDefaultPrice < ActiveRecord::Migration
  def self.up
    change_column_default("universities", "subscription_charge", 24.94)
  end

  def self.down
    change_column_default("universities", "subscription_charge", 22.95)
  end
end

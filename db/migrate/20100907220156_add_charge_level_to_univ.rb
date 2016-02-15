class AddChargeLevelToUniv < ActiveRecord::Migration
  def self.up
    add_column     :universities, :charge_level, :integer, :null => false, :default => 1
    University.all.each do |u|
      u.update_attributes(:charge_level => { 22.95 => 1, 25.95 => 2, 27.95 => 3}[u.subscription_charge.to_f] )
    end
  end
  
  def self.down
    remove_column     :universities, :charge_level
  end
end

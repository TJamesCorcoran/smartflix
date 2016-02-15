class AddDeathTypeNoaddr < ActiveRecord::Migration
  def self.up
    DeathType.create!(:name => "lost_by_cust_no_addr")
  end

  def self.down
    DeathType.find_by_name("lost_by_cust_no_addr").destroy
  end
end

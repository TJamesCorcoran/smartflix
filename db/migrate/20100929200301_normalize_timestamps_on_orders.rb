class NormalizeTimestampsOnOrders < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE orders MODIFY COLUMN  orderDate date AFTER prereqMsgSentP")
    execute("ALTER TABLE orders MODIFY COLUMN  created_at datetime AFTER orderDate")
    add_column     :orders, :updated_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"
    change_column  :orders, :created_at, :timestamp, :null => false, :default =>"0000-00-00 00:00:00"	
  end

  def self.down
    execute("ALTER TABLE orders MODIFY COLUMN  created_at datetime  AFTER ip_address")
    execute("ALTER TABLE orders MODIFY COLUMN  orderDate datetime  AFTER postcheckout_sale")
    remove_column     :orders, :updated_at
  end
end

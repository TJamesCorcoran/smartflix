class InventoryOrdered < ActiveRecord::Base
  self.primary_key = "inventory_ordered_id"
  attr_protected # <-- blank means total access

  belongs_to :product

  def validate
    if (quant_dvd < 0 )
      errors.add(:quant_dvd, "0 is minimum legal value" )
    end
  end

  def self.delayed_vendor_orders
   InventoryOrdered.find_by_sql("SELECT  io.*, recent
                                 FROM inventory_ordereds io, 
                                     ( SELECT product_id, max(orderDate) as recent 
                                       FROM vendor_order_logs 
                                       WHERE quant > 0 
                                       GROUP BY product_id 
                                       ORDER BY product_id) recentOrders
                                WHERE quant_dvd > 0 
                                AND io.product_id = recentOrders.product_id 
                                AND ((TO_DAYS(NOW()) - TO_DAYS(recent)) > 30) 
                                ORDER BY recent")
  end

end

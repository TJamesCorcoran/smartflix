class AddCancelBitToOrder < ActiveRecord::Migration
  def self.up
    add_column     :orders, :live, :boolean, :default => true

    # update the data 
    #
    live = dead = 0
    orders = Order.find(:all, :conditions => "university_id")
    puts "total: #{orders.size}"
    orders.each do |order|
      active = order.any_pending? || order.any_in_field?
      if active
        live += 1
        puts "* LIVE #{order.customer.email}"
      else
        order.update_attributes!(:live => false)
        dead += 1
        puts "* DEAD #{order.customer.email} // #{order.order_id}"
      end
    end
    puts "live count: #{live}"
    puts "dead count: #{dead}"
  end

  def self.down
    remove_column   :orders, :live
  end
end

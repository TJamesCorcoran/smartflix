class AddServernameToCustomer < ActiveRecord::Migration
  def self.up
    add_column :customers, :first_server_name,   :string
    add_column :customers, :first_ip_addr,       :string
    add_column :customers, :first_university_id, :integer
    Order.find(:all, :conditions => "server_name != 'smartflix.com'", :order => 'order_id').each do |order|
      order.customer.update_attribute(:first_server_name, order.server_name) unless order.customer.first_server_name
    end
    execute "UPDATE customers SET first_server_name = 'smartflix.com' WHERE ISNULL(first_server_name)"
  end

  def self.down
    remove_column :customers, :first_server_name
    remove_column :customers, :first_ip_addr
    remove_column :customers, :first_university_id
  end
end

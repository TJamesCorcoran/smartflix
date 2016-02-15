class AddFakePaymentsToExistingBackendOrders < ActiveRecord::Migration
  def self.up
    Order.ERRORCHECK_payments_exist.each do |order|
      new_payment = Payment.create(:amount => 0.00,
                                   :amount_as_new_revenue => 0.00,
                                   :complete => 1,
                                   :successful => 1,
                                   :payment_method => "backend",
                                   :message => "backend - fake payment created in migration #20100326164750", 
                                   :customer => order.customer)
      order.payments << new_payment
      puts "* order #{order.id} done"
    end
  end

  def self.down
    puts "doing nothing"
  end
end

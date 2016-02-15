class Cobrand < ActiveRecord::Base
  self.primary_key = "cobrand_id"
  attr_protected # <-- blank means total access

  has_many :cobrand_categories
  has_many :categories, :through => :cobrand_categories, :order => 'ordinal'
  has_many :cobrand_payments

  def sum_cobrand_payments
    cobrand_payments.inject(0.0) { |sum, cp| sum + cp.payment}
  end

  def orders
    Order.find_by_sql("select * from orders co where co.name = '#{self.name}'")
  end

  def sum_order_payments
    Cobrand.connection.select_one("select sum(price) as sum from line_items li, orders co where li.order_id = co.order_id and co.server_name = '#{self.name}'")['sum'].to_f
  end

  def commissions
    sum_order_payments.to_f * commission.to_f
  end

end

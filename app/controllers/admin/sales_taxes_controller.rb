
class Admin::SalesTaxesController < Admin::Base

  def index
    lis = LineItem.find_by_sql("SELECT line_items.* from line_items, orders, customers, addresses, states
                                WHERE line_items.order_id = orders.order_id
                                AND orders.customer_id = customers.customer_id
                                AND customers.shipping_address_id = addresses.address_id
                                AND addresses.state_id = states.state_id
                                AND states.code = 'MA'
                                AND ISNULL(university_id)
                                AND line_items.live = 1")
    @sales_taxes = Hash.new
    lis.each do |li|
      dd = li.order.orderDate
      key = "#{dd.year} q#{dd.quarter}"
      if (@sales_taxes[key].nil?) then @sales_taxes[key] = 0 end
      @sales_taxes[key] += (li.price * 0.9523)
    end

    respond_to do |format|
      format.html
    end
  end

end

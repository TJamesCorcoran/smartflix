# Filters Admin::added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

# Given a customer, an optional start date, and an optional end date,
# return the revenue and profit from that customer (during the time
# period in question, or over all time) as well as the number of copies
# and number of orders and number of shipments

def revenue_and_profit(cust_id, start_date = nil, end_date = nil)

  start_date = Date.parse('0000-01-01') if (start_date.nil?)
  end_date   = Date.parse('3000-01-01') if (end_date.nil?)

  order_data = CustomerOrder.find_by_sql("SELECT SUM(price) AS total,
                                                 COUNT(1) AS copies,
                                                 COUNT(DISTINCT(orders.orderID)) AS orders
                                            FROM orders, lineItem
                                           WHERE orders.customer_id = #{cust_id}
                                             AND orders.orderID = lineItem.orderID
                                             AND lineItem.live = 1
                                             AND orderDate >= '#{start_date.to_s}'
                                             AND orderDate <= '#{end_date.to_s}'")[0]

  revenue = order_data.total.to_f
  copies = order_data.copies.to_f
  orders = order_data.orders.to_f

  costs = 0.0

  ##############################################
  # Processing costs, as percent of total inflow
  ##############################################

  # 2.19% credit card processing fees
  processing_fee_perc = 0.0219

  costs += revenue * processing_fee_perc

  #################
  # Per order costs
  #################

  # $0.49 per-transaction credit card processing fee
  processing_fee_flat = 0.49

  costs += orders * processing_fee_flat

  ###############
  # Per DVD costs
  ###############

  # $1.50 / DVD depreciation
  depreciation = 1.50

  # $0.50 / DVD shipping labor
  shipping_labor = 0.50

  costs += copies * (depreciation + shipping_labor)

  ####################
  # Per shipment costs
  ####################

  # $0.04 outgoing label (label and laser)
  outgoing_label = 0.04

  # $0.05 return label
  return_label = 0.05

  # $0.06 instructions
  instructions = 0.06

  # $0.11 adhesive tabs
  adhesive_tabs = 0.11

  # $0.13 postage machine rental and ink
  postage_machine = 0.13

  # Mail shipping rates, based on number of DVDs
  shipping_rates = { 1 => 0.87, 2 => 0.87, 3 => 1.11, 4 => 1.35, 5 => 1.83,
                     6 => 2.07, 7 => 2.31, 8 => 2.31, 9 => 2.55, 10 => 2.79 }

  # Shipping containers, based on number of DVDs
  shipping_containers = { 1 => 0.46, 2 => 0.46, 3 => 0.46, 4 => 0.46 }
  # Everything not 1-4 costs 0.60
  shipping_containers.default = 0.60

  # lookup table for cost per shipment, based on shipment size

  shipment_costs = Hash.new(10.00) # default for customers with > 10 items left to ship, might be low?

  shipping_rates.each_key do |size|
    shipment_costs[size] = (shipping_rates[size] * 2) + shipping_containers[size] + outgoing_label +
      return_label + instructions + adhesive_tabs + postage_machine
  end

  # Note: this assumes all unshipped items will be bundled together
  shipments = CustomerOrder.find_by_sql("SELECT shipmentID, count(1) as size
                                           FROM orders, lineItem
                                          WHERE orders.customer_id = #{cust_id}
                                            AND orders.orderID = lineItem.orderID
                                            AND lineItem.live = 1
                                            AND orderDate >= '#{start_date.to_s}'
                                            AND orderDate <= '#{end_date.to_s}'
                                       GROUP BY shipmentID")

  shipments.each { |shipment| costs += shipment_costs[shipment.size.to_i] }

  # We don't need to include reship rate, since reshipments have line
  # items that are included here, with $0.00 revenue attached

  profit = revenue - costs

  return revenue, profit, copies, orders, shipments.size.to_i

end

class TableDisplayer


  def initialize()
    @rows = Array.new()
  end

  def columns(*cols)
    @cols = cols
  end

  def row(*cols)
    @rows << cols
  end

  def to_s()

    # Build a table with headers
    table = "<table class=\"sortable\" id=\"table_id\" cellpadding=\"3\"><tr>"
    
    @cols.each { |col| table += "<th align=center>#{col.to_s}</th>" }

    table += "</tr>"

    # Output the contents of each row
    rowcolor = "#E0E0E0"
    @rows.each do |row|
      # Write the row
      table += "<tr bgcolor=\"#{rowcolor}\">"
      row.each { |element| table += "<td align=\"right\">#{element}</td>" }
      table += "</tr>\n"
      # Flip the background color
      rowcolor = (rowcolor == "#FFFFFF") ? "#E0E0E0" : "#FFFFFF"
    end
    
    table += "</table>"
    
    return table

  end
end

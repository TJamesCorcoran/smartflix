class Admin::CampaignController < Admin::Base



  def index()

    @optimism_multiplier = (params[:o] && params[:o].to_i > 0) ? params[:o].to_i : 1

    @start_date = (params[:s] && params[:s] =~ /\d\d\d\d-\d\d-\d\d/) ? Date.parse(params[:s]) : Date.today()
    @end_date = (params[:e] && params[:e] =~ /\d\d\d\d-\d\d-\d\d/) ? Date.parse(params[:e]) : nil

    build_campaign_table()

    build_walkin_table()

  end

  #####################################################################
  # Build the table for established advertising and marketing campaigns
  #####################################################################

  def build_campaign_table()

    # Build a simple table
    @campaign_table = TableDisplayer.new()

    # Specify the column headings
    @campaign_table.columns('Campaign',
                            'Total Cost',
                            'Revenue',
                            '1 Month Profit',
                            '2 Month Profit',
                            'Total Profit',
                            'Cost / Profit',
                            '# Cust',
                            'Cost / Cust',
                            'Profit / Cust',
                            'Bottom Line')

    # One row for each campaign

    Campaign.find(:all, :order => 'campaign_name').each do |campaign|

      # Grab basic data stored in DB

      name = campaign.campaign_name
      fixed_cost = campaign.fixed_cost.to_f
      unit_cost = campaign.unit_cost.to_f

      # Query to get all customers that result from this campaign

      conditions = Array.new()

      if (campaign.coupon && campaign.coupon.length > 0)
        conditions << "first_coupon REGEXP '^#{campaign.coupon}$'"
      end

      if (campaign.initial_uri_regexp && campaign.initial_uri_regexp.length > 0)
        conditions << "first_uri REGEXP '#{campaign.initial_uri_regexp}'"
      end

      conditions << "customer_origins.customer_id = firstOrders.customer_id"

      conditions << "firstOrders.orderDate >= '#{campaign.start_date.to_s}'"

      if (campaign.end_date)
        conditions << "firstOrders.orderDate <= '#{campaign.end_date.to_s}'"
      end

      customers = Origin.find(:all,
                                      :joins => 'JOIN (SELECT customer_id, min(orderDate) AS orderDate
                                                         FROM orders
                                                     GROUP BY customer_id) AS firstOrders',
                                      :conditions => conditions.join(' AND '))

      customer_count = customers.size

      # Add up the total cost

      total_cost = fixed_cost + customer_count * unit_cost

      # Factor in optimism

      customer_count *= @optimism_multiplier

      # Figure cost per customer

      cost_per_customer = total_cost / customer_count

      # Go through all customers and figure out total revenue and profit

      revenue = 0.0
      profit = 0.0
      profit_m1 = 0.0
      profit_m2 = 0.0

      customers.each do |customer|

        this_revenue, this_profit = revenue_and_profit(customer.id, campaign.start_date)
        revenue += this_revenue
        profit += this_profit

        this_revenue, this_profit = revenue_and_profit(customer.id,
                                                       campaign.start_date,
                                                       campaign.start_date >> 1)
        profit_m1 += this_profit

        this_revenue, this_profit = revenue_and_profit(customer.id,
                                                       campaign.start_date,
                                                       campaign.start_date >> 2)
        profit_m2 += this_profit

      end

      # Factor in optimism

      revenue *= @optimism_multiplier
      profit *= @optimism_multiplier
      profit_m1 *= @optimism_multiplier
      profit_m2 *= @optimism_multiplier

      cost_per_profit = total_cost / profit

      profit_per_customer = profit / customer_count

      bottom_line = profit - total_cost

      @campaign_table.row(name,
                          "$%.2f" % total_cost,
                          "$%.2f" % revenue.to_f,
                          "$%.2f" % profit_m1.to_f,
                          "$%.2f" % profit_m2.to_f,
                          "$%.2f" % profit.to_f,
                          "$%.2f" % cost_per_profit.to_f,
                          "%d"    % customer_count.to_f,
                          "$%.2f" % cost_per_customer.to_f,
                          "$%.2f" % profit_per_customer.to_f,
                          "$%.2f" % bottom_line.to_f)

    end

  end

  #####################################################################
  # Build the table for general referer tracking
  #####################################################################

  def build_walkin_table()

    # Build a simple table
    @walkin_table = TableDisplayer.new()

    # Specify the column headings
    @walkin_table.columns('Referer',
                          'Revenue',
                          'Total Profit',
                          '# Cust',
                          'Profit / Cust')

    start_date = @start_date ? @start_date : Date.parse('0000-01-01')
    end_date = @end_date ? @end_date : Date.parse('3000-01-01')

    # Look through all referers and get the top level list of domains
    origins = Origin.find_by_sql("SELECT customer_origins.referer, customer_origins.customer_id
                                            FROM customer_origins, (SELECT customer_id, min(orderDate) AS orderDate
                                                             FROM orders
                                                         GROUP BY customer_id) AS firstOrders
                                           WHERE customer_origins.customer_id = firstOrders.customer_id
                                             AND firstOrders.orderDate >= '#{start_date.to_s}'
                                             AND firstOrders.orderDate <= '#{end_date.to_s}'
                                             AND (ISNULL(first_uri) OR first_uri NOT LIKE '%ga=1%')
                                             AND ISNULL(first_coupon)
                                        GROUP BY customer_origins.customer_id")

    urls = Hash.new() { |hash, key| hash[key] = Array.new() }

    origins.each do |origin|
      match = /:\/\/(www.)?([a-zA-Z0-9._-]+)\//.match(origin.referer)
      urls[match[2].to_s] << origin.customer_id if (match)
      urls['DIRECT'] << origin.customer_id if origin.referer.nil?
    end

    urls.each do |url, cust_ids|

      customer_count = cust_ids.size

      # Go through all customers and figure out total revenue and profit

      revenue = 0.0
      profit = 0.0

      cust_ids.each do |cust_id|

        this_revenue, this_profit = revenue_and_profit(cust_id, start_date, end_date)
        revenue += this_revenue
        profit += this_profit

      end

      profit_per_customer = profit / customer_count

      @walkin_table.row(url,
                        "$%.2f" % revenue,
                        "$%.2f" % profit,
                        "%d"    % customer_count,
                        "$%.2f" % profit_per_customer)

    end

  end

end


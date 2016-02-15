require 'pp'
# TO DO
#   1) the :per_day => true flag could be applied in many more places, reducing lines of code
#   2) a :per_year flag could be added
#   3) most of the queries can be moved to the models, giving us better abstraction and
#        reducing LOC in this
#


# To add a new stat, add this code in the index() function
#
#
#            @stats.add(:dh =>                   // mandatory.  What should we call this stat? 
#                       :name => base_name,      // optional / historic.  What sym should we use to
#                                                //     refer to this stats?  If not present, derived from
#                                                //     dh
#
#
#                       :indent =>               // optional: level of indent (defaults to 0)
#                       :display_format =>       // optional: either sprintf string or "currency"
#                                                //     defaults to "%d"
#                       :per_day => true,        // optional: create an indented derived stat?
#                       :growth => true,         // optional: create an indented derived stat?
#
#
#                       :controller =>           // optional: creates link_to
#                       :action =>               // optional: creates link_to
#                       :action_args => { }
#                       ) do |fday, lday, ndays, tdays, prev|
#
#                // meat goes here, using args
#                //     fday, lday, ndays, tdays, prev
#                // must return a string, int, or what-have-you.
#            end


class Admin::StatsController < Admin::Base

  private
  # GIVEN: two arrays of data and student's t-distribution
  # ...find the delta between the means, and the 95% confidence range on
  # what the difference between the means REALLY is.
  #
  def confidence(data1, data2, conf)
    d1 = data1.to_statarray
    d2 = data2.to_statarray
    diff = d2.mean - d1.mean
    plus_minus = conf * Math.sqrt( d1.variance  / d1.size  + d2.variance / d2.size)
    [diff, diff - plus_minus, diff + plus_minus ]
  end

  public
  def index()

    # Passed in arguments... time period, number of periods, and confidence
    # desired for A/B stuff

    period = params[:p] ? params[:p] : "month"
    nPeriods = params[:n] ? params[:n].to_i : 6

    confidence = case params[:c].to_i
                 when 99 ; 2.58
                 when 95 ; 1.96
                 when 90 ; 1.645
                 when 80 ; 1.282
                 else ; 1.96
                 end

    current_period_fday = Date.first_day_of_current_period(period)

    #######################################################################
    # Create a stats object, and populate it with the statistics we want to
    # collect and calculate; the stats object is then displayed in the view
    # via a call to @stats.display()
    #######################################################################

    @stats = Stats.new(params, period, nPeriods)

    ###############################
    # the new META system
    ###############################

    [ CcChargeStatus ].each do |class_name|
      class_name.methods.select {|method_name| method_name.match(/^STATS_/) && class_name.method(method_name).arity == 2}.each do |method_name|
        display_format = nil
        if method_name.match(/_CURRENCY$/)
          display_format  = "currency"
        end

        display_method = method_name.to_s.gsub(/^STATS_/,'').gsub(/_CURRENCY$/,'')
        display_heading = "#{class_name.to_s}::#{display_method}"

        @stats.add(:display_heading => display_heading, :display_format => display_format, :per_day => true) do |fday, lday, ndays, tdays|
          class_name.send(method_name, fday, lday)
        end
      end
    end



    #######################################################################
    # University 
    #######################################################################

    @stats.add(:display_heading => "university subs") do |fday, lday, ndays, tdays|
      Order.live_university_count(lday)
    end

    #######################################################################
    # Revenue 
    #######################################################################

    @stats.add(:display_heading => "revenue (charge type)") do |fday, lday, ndays, tdays|
      ""
    end

     Order.charge_types_for_stats.each do |charge_type|
    
             # revenue
             base_heading = "revenue #{charge_type.to_s}"
             base_name = base_heading.to_sym_clean
             @stats.add(:display_heading => base_heading,
                        :name => base_name,
                        :indent => 1,
                        :display_format => "currency", # "$%.0f",
                        :controller => :orders,
                        :action => :index,
                        :per_day => true,
                        :growth => true,
                        :action_args => { :charge_type => charge_type }
                      
                        ) do |fday, lday, ndays, tdays|

                 Order.STATS_revenue_of_type_x(fday, lday, charge_type)
             end

     end # Order.charge_types.each ...  end

    @stats.add(:display_heading => "rental revenue (customer type)",
               :display_format => "") do |fday, lday, ndays, tdays|
      ""
    end

    @stats.add(:display_heading => "customer from this period",
               :indent => 1) do |fday, lday, ndays, tdays|
      Order.revenue_from_custs_of_this_period(fday, lday).to_i
    end

    @stats.add(:display_heading => "customer from prev period",
               :indent => 1) do |fday, lday, ndays, tdays|
      Order.revenue_from_custs_of_prev_period(fday, lday).to_i
    end


    
    #######################################################################
    # Order source 
    #######################################################################

    @stats.add(:display_heading => "order source",
               :display_format => "") do |fday, lday, ndays, tdays|
      ""
    end

    @stats.add(:display_heading => "newsletter",
               :indent => 1,
               :display_format => "$%.0f",
               :controller => :orders,
               :action => :index,
               :action_args => { :source => "newsletter" }) do |fday, lday, ndays, tdays|
      Order.revenue_via_newsletter(fday, lday)
    end

    @stats.add(:display_heading => "google ad",
               :indent => 1,
               :display_format => "$%.0f",
               :controller => :orders,
               :action => :index,
               :action_args => { :source => "google ad" }) do |fday, lday, ndays, tdays|
      Order.revenue_via_googlead(fday, lday)
    end

    @stats.add(:display_heading => "affiliate",
               :indent => 1,
               :display_format => "$%.0f",
               :controller => :orders,
               :action => :index,
               :action_args => { :source => "affiliate" }) do |fday, lday, ndays, tdays|
      Order.revenue_via_affiliate(fday, lday)
    end

    @stats.add(:display_heading => "other online",
               :indent => 1,
               :display_format => "$%.0f",
               :controller => :orders,
               :action => :index,
               :action_args => { :source => "other online" }) do |fday, lday, ndays, tdays|
      Order.revenue_via_other_online_ad(fday, lday)
    end

    
    #######################################################################
    # New customers and their actions
    #######################################################################

    @stats.add(:dh => "New Customers Funnel", :display_format => "") do |fday, lday, ndays, tdays|
      ""
    end

    @stats.add(:dh => "Visitors", :indent=>1) do |fday, lday, ndays, tdays|
      Customer.STATS_num_visitors(fday, lday)  
    end

    @stats.add(:dh => "New Visitors", :indent=>1) do |fday, lday, ndays, tdays|
      Customer.STATS_num_new_visitors(fday, lday)  
    end
    
    @stats.add(:dh => "New Customers - total", :indent=>1, :per_day => true, :growth => true) do |fday, lday, ndays, tdays|
      Customer.STATS_num_new_customers(fday, lday)  
    end

    @stats.add(:dh => "New Customers - email capture TRUE", :indent=>2, :per_day => true, :growth => true) do |fday, lday, ndays, tdays|
      Customer.STATS_num_new_customers_email_capture_yes(fday, lday)  
    end

    @stats.add(:dh => "New Customers - email capture FALSE", :indent=>2, :per_day => true, :growth => true) do |fday, lday, ndays, tdays|
      Customer.STATS_num_new_customers_email_capture_no(fday, lday)        
    end

    @stats.add(:display_heading => "New Customers - full customers", :indent=>1) do |fday, lday, ndays, tdays|
      Customer.STATS_num_full_customers(fday, lday, nil)
    end

    @stats.add(:display_heading => "...upgraded from email capture TRUE", :indent=>2) do |fday, lday, ndays, tdays|
      Customer.STATS_num_full_customers(fday, lday, true)
    end

    @stats.add(:display_heading => "New Customers - first order", :indent=>1, :per_day => true, :growth => true) do |fday, lday, ndays, tdays|
      Customer.STATS_num_first_orders(fday, lday)
    end

    @stats.add(:display_heading => "New Customers - university order", :indent=>1, :per_day => true, :growth => true) do |fday, lday, ndays, tdays|
      Customer.STATS_num_orders_university(fday, lday)
    end



    #######################################################################
    # New customers and their sources
    #######################################################################

    @stats.add(:dh => "New Customers (sources)") do |fday, lday, ndays, tdays|
      Customer.STATS_num_new_customers(fday, lday)
    end

    
    @stats.add(:display_heading => "direct",
               :indent => 1,
               :per_day =>true,
               :controller => :customers,
               :action => :index,
               :action_args => { :source => "direct" }) do |fday, lday, ndays, tdays|
      Origin.customers_direct(fday,lday,true)    
    end

    @stats.add(:display_heading => "Yahoo Search",
               :indent => 1,
               :per_day =>true,
               :controller => :customers,
               :action => :index,
               :action_args => { :source => "Yahoo Search" }) do |fday, lday, ndays, tdays|

      Origin.customers_yahoo_search(fday,lday,true)    
    end

    @stats.add(:display_heading => "Google Search",
               :indent => 1,
               :per_day =>true,
               :controller => :customers,
               :action => :index,
               :action_args => { :source => "Google Search" }) do |fday, lday, ndays, tdays|

      Origin.customers_google_search(fday,lday,true)
    end

    @stats.add(:display_heading => "Google Ads",
               :indent => 1,
               :per_day =>true,
               :controller => :customers,
               :action => :index,
               :action_args => { :source => "Google Ads" }) do |fday, lday, ndays, tdays|

      Origin.customers_google_ads(fday,lday,true)
    end

    @stats.add(:display_heading => "eBay cpn (overlaps other srcs)",
               :indent => 1,
               :per_day =>true) do |fday, lday, ndays, tdays|

      Origin.customers_ebay_coupon(fday,lday,true)    
    end

    @stats.add(:display_heading => "eBay referer",
               :indent => 1,
               :per_day =>true) do |fday, lday, ndays, tdays|

      Origin.customers_ebay(fday,lday,true)    
    end

    @stats.add(:display_heading => "other referer",
               :indent => 1,
               :per_day =>true,
               :controller => :customers,
               :action => :index,
               :action_args => { :source => "other referer" }
               ) do |fday, lday, ndays, tdays|
      Origin.customers_other(fday,lday,true)    
    end



    #######################################################################
    # Orders placed
    #######################################################################

    @stats.add(:name => :orders,
               :display_heading => "Orders placed",
               :per_day => true,
               :growth => true ) do |fday, lday, ndays, tdays|

      Order.count("orderDate >= \"#{fday.to_s}\" AND orderDate <= \"#{lday.to_s}\"")

    end

    
    #######################################################################
    # Campaigns w start dates here
    #######################################################################

    @stats.add(:name => :campaigns_starting,
               :display_heading => "campaigns starting",
               :display_format => "%i") do |fday, lday, ndays, tdays|

      Copy.find_by_sql("SELECT count(1) as cnt
                        FROM campaigns 
                        WHERE TO_DAYS(start_date) >= TO_DAYS(\"#{fday.to_s}\")
                        AND   TO_DAYS(start_date) <= TO_DAYS(\"#{lday.to_s}\")"
                            )[0].cnt.to_i
    end

        @stats.add(:name => :campaigns_starting_print,
                   :indent => 1,
                   :display_heading => "print",
                   :display_format => "%i") do |fday, lday, ndays, tdays|

          Copy.find_by_sql("SELECT count(1) as cnt
                            FROM campaigns 
                            WHERE  ISNULL(initial_uri_regexp)
                            AND TO_DAYS(start_date) >= TO_DAYS(\"#{fday.to_s}\")
                            AND TO_DAYS(start_date) <= TO_DAYS(\"#{lday.to_s}\")"
                                )[0].cnt.to_i
        end

         @stats.add(:name => :campaigns_starting_online,
                   :indent => 1,
                   :display_heading => "online",
                   :display_format => "%i") do |fday, lday, ndays, tdays|

          Copy.find_by_sql("SELECT count(1) as cnt
                            FROM campaigns 
                            WHERE  ! ISNULL(initial_uri_regexp)
                            AND TO_DAYS(start_date) >= TO_DAYS(\"#{fday.to_s}\")
                            AND TO_DAYS(start_date) <= TO_DAYS(\"#{lday.to_s}\")"
                                )[0].cnt.to_i
        end

    
    #######################################################################
    # The One Question / customer happiness
    #######################################################################

    @stats.add(:name => :customer_happiness,
               :display_heading => "customer happiness",
               :display_format => "%.2f") do |fday, lday, ndays, tdays|

      Copy.find_by_sql("SELECT AVG(IF(answer >= 9, answer, 0) - IF(answer <= 6, answer, 0)) as 'score'
                            FROM    survey_answers
                            WHERE   TO_DAYS(created_at) >= TO_DAYS(\"#{fday.to_s}\")
                            AND TO_DAYS(created_at) <= TO_DAYS(\"#{lday.to_s}\")"
                            )[0].score.to_f
    end


    
    #######################################################################
    # rejected overdue charges (new)
    #######################################################################

    @stats.add(:name => :overdueChargesRejectedNew,
               :display_heading => "overdue charges rejected (new)",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      # find declined charges
      declined = CcChargeStatus.find(:all, :conditions => "DATE(created_at) >= '#{fday.to_s}' AND DATE(created_at) <= '#{lday.to_s}'")

      # a given person X may have 3 cards, and we tried and failed on
      # all of them.  For each such person, just pick the first card
      # that got declined and sum that amount - don't double (or
      # triple!) count.
      declined.group_by(&:credit_card).values.map(&:first).inject(0){ |sum, status| sum + status.amount}.to_f

      # XYZFIX P3: if a person had 2 cards and the first one failed,
      # and the next succeeded, we falsely count that here.
      
      # XYZFIX P4: if we try to charge person X for order A and fail,
      # then 29 days later try to charge them for order B and fail, we
      # incorrectly fail to count order B...which we should.      
    end

    @stats.add(:name => :overdueChargesRejectedSum,
               :display_heading => "overdue charges rejected (sum)",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      declined = CcChargeStatus.find(:all, :conditions => "DATE(created_at) <= '#{lday.to_s}'")
      declined.group_by(&:credit_card).values.map(&:first).inject(0){ |sum, status| sum + status.amount}.to_f
      # all comments as above
    end

    @stats.add(:display_heading => "Copies Ordered",
               :per_day => true,
               :growth => true) do |fday, lday, ndays, tdays|

      Customer.count_by_sql("
        SELECT COUNT(1) FROM line_items, orders
                       WHERE line_items.order_id = orders.order_id
                         AND line_items.apologyCopyP = 0
                         AND line_items.live = 1
                         AND orders.orderDate >= \"#{fday.to_s}\"
                         AND orders.orderDate <= \"#{lday.to_s}\"")
    end

    @stats.add(:name => :copiesShipped,
               :display_heading => "Copies Shipped") do |fday, lday, ndays, tdays|

      # We include apology copies here, since this is mostly used to calculate
      # labor costs per item shipped

      Customer.count_by_sql("
        SELECT COUNT(1) FROM line_items, shipments
                       WHERE line_items.shipments_id = shipments.shipments_id
                         AND shipments.dateOut >= \"#{fday.to_s}\"
                         AND shipments.dateOut <= \"#{lday.to_s}\"")
    end

            @stats.add(:name => :copiesShipped_boxes,
                       :indent => 1,
                       :display_heading => "Copies Shipped - boxes") do |fday, lday, ndays, tdays|

              # We include apology copies here, since this is mostly used to calculate
              # labor costs per item shipped

              Customer.count_by_sql("
                SELECT COUNT(1) FROM line_items, shipments
                               WHERE line_items.shipments_id = shipments.shipments_id
                                 AND shipments.dateOut >= \"#{fday.to_s}\"
                                 AND shipments.dateOut <= \"#{lday.to_s}\"
                                 AND boxP = 1")
            end

            @stats.add(:name => :copiesShipped_envelopes,
                       :indent => 1,
                       :display_heading => "Copies Shipped - envelopes") do |fday, lday, ndays, tdays|

              # We include apology copies here, since this is mostly used to calculate
              # labor costs per item shipped

              Customer.count_by_sql("
                SELECT COUNT(1) FROM line_items, shipments
                               WHERE line_items.shipments_id = shipments.shipments_id
                                 AND shipments.dateOut >= \"#{fday.to_s}\"
                                 AND shipments.dateOut <= \"#{lday.to_s}\"
                                 AND boxP = 0")
            end



    #   XYZ FIX P3: This only counts the number fully resurrected;
    #        If 5 are polished and 0 test out as OK, then this will show zero.
    @stats.add(:name => :copiesPolished,
               :display_heading => "Copies Polished") do |fday, lday, ndays, tdays|

      DeathLog.count_by_sql("
        SELECT COUNT(1) FROM death_logs
                       WHERE newDeathType = 0
                         AND editDate >= \"#{fday.to_s}\"
                         AND editDate <= \"#{lday.to_s}\"")
    end

    @stats.add(:name => :copiesInventoried,
               :display_heading => "Copies Inventoried") do |fday, lday, ndays, tdays|

      Inventory.count_by_sql("
        SELECT sum(copyCount) FROM inventories
                       WHERE inventoryDate >= \"#{fday.to_s}\"
                         AND inventoryDate <= \"#{lday.to_s}\"")
    end


    @stats.add(:display_heading => "Shipments") do |fday, lday, ndays, tdays|

      Customer.count_by_sql("
        SELECT COUNT(1) FROM shipments
                       WHERE shipments.dateOut >= \"#{fday.to_s}\"
                         AND shipments.dateOut <= \"#{lday.to_s}\"")
    end

    @stats.add(:indent => 1,
               :display_heading => "Shipments - boxes") do |fday, lday, ndays, tdays|

      Customer.count_by_sql("
        SELECT COUNT(1) FROM shipments
                       WHERE shipments.dateOut >= \"#{fday.to_s}\"
                         AND shipments.dateOut <= \"#{lday.to_s}\"
                         AND boxP = 1")
    end

    @stats.add(:indent => 1,
               :display_heading => "Shipments - envelopes") do |fday, lday, ndays, tdays|

      Customer.count_by_sql("
        SELECT COUNT(1) FROM shipments
                       WHERE shipments.dateOut >= \"#{fday.to_s}\"
                         AND shipments.dateOut <= \"#{lday.to_s}\"
                         AND boxP = 0")
    end

#     @stats.add(:name => :expectedLabor,
#                :display_heading => "Expected Shipping time (hours)",
#                :depends_on => [:dvdsIn, :copiesShipped, :copiesPolished, :copiesInventoried],
#                :display_format => "%.0f") do |fday, lday, ndays, tdays|

#       ((
#         (@stats[:dvdsIn][fday] * 0.5) +
#         (@stats[:copiesShipped][fday] * 2).to_f +
# # +        (@stats[:copiesPolished][fday] * 10).to_f    # suz does most polishing these days
#   +        (@stats[:copiesInventoried][fday] * 0.05).to_f
#        ) / 60 * 0.8
#        )
#     end


#     @stats.add(:name => :actualLaborJulio,
#                :display_heading => "Actual shipping labor (Julio)",
#                :indent => 1,
#                :display_format => "%.0f") do |fday, lday, ndays, tdays|
#       TimesheetItem.find_by_sql("SELECT SUM(TIMEDIFF(end, begin)) as 'hours'
#                                  FROM   hr_timesheet_items 
#                                  WHERE  hr_person_id in (10)
#                                  AND hr_timesheet_items.date  >= \"#{fday.to_s}\"
#                                  AND hr_timesheet_items.date  <= \"#{lday.to_s}\""
#                                  )[0].hours.to_f    # on my local machine, I want " / 3600", on helium, not so much
#     end

#     @stats.add(:name => :actualLaborSmartFlix,
#                :display_heading => "Actual shipping labor on SmartFlix",
#                :indent => 1,
#                :depends_on => [:actualLaborJandM, :actualLaborJulio],
#                :display_format => "%.0f") do |fday, lday, ndays, tdays|

#       julio_coeff = 1.0
#       if fday >= Date.strptime("2008-01-01", "%Y-%m-%d" ) and fday <= Date.strptime("2008-01-31", "%Y-%m-%d" )
#         julio_coeff = 0.75
#       elsif fday >= Date.strptime("2008-02-01", "%Y-%m-%d" ) and fday <= Date.strptime("2008-02-29", "%Y-%m-%d" )
#         julio_coeff = 0.50
#       elsif fday >= Date.strptime("2008-03-01", "%Y-%m-%d" ) and fday <= Date.strptime("2008-03-31", "%Y-%m-%d" )
#         julio_coeff = 0.25
#       elsif fday >= Date.strptime("2008-04-01", "%Y-%m-%d" ) 
#         julio_coeff = 0.0
#       end
#       @stats[:actualLaborJandM][fday] + ( julio_coeff * @stats[:actualLaborJulio][fday])
#     end

#     @stats.add(:name => :laborRatio,
#                :display_heading => "Ratio of expected / actual shipping labor",
#                :indent => 1,
#                :depends_on => [:expectedLabor, :actualLaborSmartFlix],
#                :display_format => "%.2f") do |fday, lday, ndays, tdays|

#        @stats[:expectedLabor][fday] /  @stats[:actualLaborSmartFlix][fday]
#     end

    
    
#     @stats.add(:name => :copiesPerOrder,
#                :depends_on => [:copies, :orders],
#                :display_heading => "Copies / Order",
#                :display_format => "%.1f") do |fday, lday, ndays, tdays|
#       @stats[:copies][fday].to_f / @stats[:orders][fday].to_f
#     end


    @stats.add(:name => :frontPageviews,
               :display_heading => "Front Pageviews") do |fday, lday, ndays, tdays|

      Copy.find_by_sql("SELECT SUM(frontPageViews) as frontPageViewsSum
                               FROM webstats
                              WHERE date >= '#{fday.to_s}'
                                AND date <= '#{lday.to_s}'
                            ")[0].frontPageViewsSum.to_i

    end


    @stats.add(:name => :pagerank,
               :display_heading => "pagerank",
               :display_format => "%.2f") do |fday, lday, ndays, tdays|

      pr = Pagerank.find(:all,
                    :conditions => "searchterm = 'OVERALL'
                                   AND date >= \"#{fday.to_s}\"
                                   AND date <= \"#{lday.to_s}\"")
      if pr.empty?
        pr = Pagerank.find(:all,
                    :conditions => "searchterm = 'OVERALL'
                                   AND date <= \"#{fday.to_s}\"").sort_by { |pr| pr.date }.reverse[0..0]
      end
      pr.map{|x| x.rank}.to_statarray.mean
    end


    #######################################################################
    # Copies ordered by new customers
    #######################################################################

    @stats.add(:name => :copiesByNewCustomers,
               :display_heading => "Copies by New Customers") do |fday, lday, ndays, tdays|

      ActiveRecord::Base.count_by_sql("
          SELECT COUNT(1) FROM line_items,
            (SELECT customers.customer_id AS customer_id,
                    min(orders.orderDate) AS firstOrder,
                    orders.order_id as order_id
             FROM customers, orders
             WHERE customers.customer_id=orders.customer_id
             GROUP BY customers.customer_id) AS firstOrders
          WHERE line_items.order_id = firstOrders.order_id
            AND line_items.apologyCopyP = 0
            AND line_items.live = 1
            AND firstOrders.firstOrder >= \"#{fday.to_s}\"
            AND firstOrders.firstOrder <= \"#{lday.to_s}\"")
    end

    #######################################################################
    # Percent of copies that are ordered by new customers
    #######################################################################

    @stats.add(:name => :percentCopiesByNewCustomers,
               :depends_on => [:copiesByNewCustomers, :copies],
               :indent => 1,
               :display_heading => "% Copies by New Customers",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      (@stats[:copiesByNewCustomers][fday] * 100.0) / @stats[:copies][fday]

    end

    #######################################################################
    # New customers with subsequent orders
    #######################################################################

    @stats.add(:name => :newCustomersWithSubseqOrders,
               :display_heading => "New Cust w/ Subseq Orders") do |fday, lday, ndays, tdays|

      # Here we do a manual count of the resulting number of rows, since the
      # group by does not let us count the whole...

      ActiveRecord::Base.find_by_sql("
          SELECT orders.customer_id FROM orders,
            (SELECT customers.customer_id AS customer_id,
                    orders.order_id as order_id,
                    min(orders.orderDate) AS firstOrder
             FROM customers, orders
             WHERE customers.customer_id=orders.customer_id
             GROUP BY customers.customer_id) AS firstOrders
          WHERE orders.customer_id = firstOrders.customer_id
            AND orders.order_id != firstOrders.order_id
            AND firstOrder >= \"#{fday.to_s}\"
            AND firstOrder <= \"#{lday.to_s}\"
            GROUP BY orders.customer_id").size
    end

    #######################################################################
    # Percent of new customers who place subsequent orders
    #######################################################################

    @stats.add(:name => :percentNewCustomersWithSubseqOrders,
               :depends_on => [:newCustomersWithSubseqOrders, :newCustomers],
               :indent => 1,
               :display_heading => "% New Cust w/ Subseq Orders",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      (@stats[:newCustomersWithSubseqOrders][fday] * 100.0) / @stats[:newCustomers][fday]

    end





    #######################################################################
    # Total business from new customers
    #######################################################################

    @stats.add(:name => :newCustomersAvgRevenue,
               :display_heading => "New Customers Average Total Revenue",
               :display_format => "$%.2f") do |fday, lday, ndays, tdays|

      # Query computes total for all orders for customers added in
      # period, then we get the average through computation afterwards

      custSums = Copy.find_by_sql("
                     SELECT SUM(line_items.price) as sum
                       FROM orders, line_items,
                            (SELECT customers.customer_id, min(orders.orderDate) AS firstOrder
                               FROM customers, orders
                              WHERE customers.customer_id=orders.customer_id
                           GROUP BY customers.customer_id) AS firstOrders
                      WHERE orders.customer_id = firstOrders.customer_id
                        AND orders.order_id = line_items.order_id
                        AND line_items.live = 1
                        AND firstOrder >= '#{fday.to_s}'
                        AND firstOrder <= '#{lday.to_s}'
                   GROUP BY orders.customer_id")

      total = 0.0
      custSums.each { |c| total += c.sum.to_f }

      total / custSums.size

    end

    #######################################################################
    # Total business from new customers, first n months
    #######################################################################

    [1, 2, 4, 6, 8, 10, 12].each do |n|

      @stats.add(:name => "newCustomersAvgRevenue#{n}m".to_sym,
                 :indent => 1,
                 :display_heading => "first #{n} month#{"s" if n > 1}",
                 :display_format => "%s") do |fday, lday, ndays, tdays|

        days = n * 30

        if ((fday + days) > Date.today)
          ""
        else
        custSums = Copy.find_by_sql("
                     SELECT SUM(line_items.price) as sum
                       FROM orders, line_items,
                            (SELECT customers.customer_id, MIN(orders.orderDate) AS firstOrder
                               FROM customers, orders
                              WHERE customers.customer_id=orders.customer_id
                           GROUP BY customers.customer_id) AS firstOrders
                      WHERE orders.customer_id = firstOrders.customer_id
                        AND orders.order_id = line_items.order_id
                        AND line_items.live = 1
                        AND firstOrder >= '#{fday.to_s}'
                        AND firstOrder <= '#{lday.to_s}'
                        AND DATEDIFF(orders.orderDate, firstOrders.firstOrder) <= #{days}
                   GROUP BY orders.customer_id")

        total = 0.0
        custSums.each { |c| total += c.sum.to_f }

          sprintf("$%.2f", (total / custSums.size))
        end
      end

    end

    #######################################################################
    # Inventory at period end
    #######################################################################

    @stats.add(:name => :inventory,
               :display_heading => "Inventory at Period End") do |fday, lday, ndays, tdays|

      Copy.count("birthDATE <= \"#{lday.to_s}\" AND status=1")

    end

    #######################################################################
    # Growth in inventory
    #######################################################################

    @stats.add(:name => :inventoryGrowth,
               :depends_on => [:inventory],
               :indent => 1,
               :display_heading => "growth",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays, prev|

      if (prev)
        ((@stats[:inventory][fday] - @stats[:inventory][prev]) * 100.0) / @stats[:inventory][prev]
      end

    end

    #######################################################################
    # Number of titles at period end
    #######################################################################

    @stats.add(:name => :numTitles,
               :display_heading => "Title Count at Period End") do |fday, lday, ndays, tdays|

      Copy.count_by_sql("
          SELECT COUNT(1)
            FROM (SELECT title_id, MIN(birthDATE) as birthDATE FROM copies GROUP BY title_id) sub
           WHERE birthDATE < '#{lday.to_s}';")
    end

    #######################################################################
    # Growth in number of titles
    #######################################################################

    @stats.add(:name => :titleGrowth,
               :depends_on => [:numTitles],
               :indent => 1,
               :display_heading => "growth",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays, prev|

      if (prev)
        ((@stats[:numTitles][fday] - @stats[:numTitles][prev]) * 100.0) / @stats[:numTitles][prev]
      end

    end

    #######################################################################
    # % of titles that are in stock, only calculated for current period
    #######################################################################

    @stats.add(:name => :titleStock,
               :display_heading => "% titles in stock",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      # Only calculate this for the current period
      if (fday == current_period_fday)
        res = Copy.find_by_sql("
                    SELECT COUNT(1) AS numTitles, COUNT(IF(numAvail > 0,1,NULL)) AS numAvail
                      FROM (SELECT title_id, COUNT(IF(status=1 and inStock=1,1,NULL)) AS numAvail
                              FROM copies GROUP BY title_id) AS numAvail;")

        (res[0].numAvail.to_f * 100.0) / res[0].numTitles.to_f
      else
        nil
      end

    end

    #######################################################################
    # % of copies recently inventoried
    #######################################################################

    @stats.add(:name => :recentInv,
               :display_heading => "% recent inventory",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      # Only calculate this for the current period
      if (fday == current_period_fday)
        Inventory.freshness_percent
      else
        nil
      end

    end

    #######################################################################
    # Amount of current inventory in the field
    #######################################################################

    @stats.add(:name => :copiesInField,
               :depends_on => [:inventory],
               :display_heading => "Copies in field") do |fday, lday, ndays, tdays|

      # Only calculate this for the current period
      if (fday == current_period_fday)
        @stats[:inventory][current_period_fday] - Copy.count("inStock=1 AND status=1")
      else
        nil
      end

    end

    #######################################################################
    # Percent of current inventory in the field
    #######################################################################

    @stats.add(:name => :percentInField,
               :depends_on => [:inventory],
               :indent => 1,
               :display_heading => "as percent",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      # Only calculate this for the current period
      if (fday == current_period_fday)
        ((@stats[:inventory][current_period_fday] - Copy.count("inStock=1 AND status=1")) * 100.0) / @stats[:inventory][current_period_fday]
      else
        nil
      end

    end

    #######################################################################
    # Ratio of inventory to total copies ordered
    #######################################################################

    @stats.add(:name => :inventoryRatio,
               :depends_on => [:inventory, :copies],
               :display_heading => "Inventory / Copies Ordered",
               :display_format => "%.1f") do |fday, lday, ndays, tdays|

      scale = ndays / tdays
      (@stats[:inventory][fday].to_f / @stats[:copies][fday].to_f) * scale

    end

    #######################################################################
    # Percent of total inventory ordered
    #######################################################################

    @stats.add(:name => :inventoryPercent,
               :depends_on => [:inventory, :copies],
               :display_heading => "% Inventory Ordered",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      scale = ndays / tdays
      ((@stats[:copies][fday] * 100.0) / @stats[:inventory][fday].to_f) / scale

    end

    #######################################################################
    # Dead videos
    #######################################################################

    @stats.add(:name => :deadVideos,
               :display_heading => "Dead Videos") do |fday, lday, ndays, tdays|

      Copy.count("deathDate >= \"#{fday.to_s}\" AND deathDate <= \"#{lday.to_s}\"")

    end

    #######################################################################
    # Dead videos - damaged
    #######################################################################

    # XYZFIX P2 - this stat isn't doing the right thing across multiple time slices
    DeathType.find(:all, :readonly => true).each do |dt|


      @stats.add(:name => :"deadVideos_#{dt.name}",
                 :indent => 1,
                 :display_heading => "Dead Videos - #{dt.name} - total") do |fday, lday, ndays, tdays|

        Copy.count("deathDate >= \"#{fday.to_s}\" AND deathDate <= \"#{lday.to_s}\"
                               AND ( death_type_id = #{dt.id})")

    end
    end

            #######################################################################
            # Dead videos - damaged - shipped in boxes
            #######################################################################

            @stats.add(:name => :deadVideosDamaged_boxes,
                       :indent => 1,
                       :display_heading => "Dead Videos - damaged - boxes") do |fday, lday, ndays, tdays|

              Copy.count(:joins =>"JOIN line_items ON copy.copy_id = line_items.copy_id
                                        JOIN shipment ON line_items.shipments_id = shipments.shipments_id",
                              :conditions =>
                              "deathDate >= \"#{fday.to_s}\"
                               AND deathDate <= \"#{lday.to_s}\"
                               AND ( death_type_id = 1 OR death_type_id = 8)
                               AND shipments.dateOut <= deathDate
                               AND line_items.dateBack >= deathDate
                               AND shipments.boxP = 1"
                              );

            end

            #######################################################################
            # Dead videos - damaged - shipped in envelopes
            #######################################################################

            @stats.add(:name => :deadVideosDamaged_envelopes,
                       :indent => 1,
                       :display_heading => "Dead Videos - damaged - envelopes") do |fday, lday, ndays, tdays|


                 if (@stats[:copiesShipped_envelopes][fday] == 0)
                     0
                 else
                       Copy.count(:joins =>"JOIN line_items ON copy.copy_id = line_items.copy_id
                                                 JOIN shipment ON line_items.shipments_id = shipments.shipments_id",
                                       :conditions =>
                                       "deathDate >= \"#{fday.to_s}\"
                                        AND deathDate <= \"#{lday.to_s}\"
                                        AND ( death_type_id = 1 OR death_type_id = 8)
                                        AND shipments.dateOut <= deathDate
                                        AND line_items.dateBack >= deathDate
                                        AND shipments.boxP = 0"
                                       );
                   end
             end

            #######################################################################
            # Dead videos - damaged - shipped in boxes - percent
            #######################################################################

            @stats.add(:name => :deadVideosDamaged_boxes_percent,
                       :indent => 1,
                       :display_heading => "Dead Videos - damaged - boxes - percent",
                       :depends_on => [:copiesShipped_boxes, :deadVideosDamaged_boxes ],
                       :display_format => "%.2f%%") do |fday, lday, ndays, tdays|

               (@stats[:deadVideosDamaged_boxes][fday] * 100.0) / @stats[:copiesShipped_boxes][fday]

            end

            #######################################################################
            # Dead videos - damaged - shipped in envelopes - percent
            #######################################################################

            @stats.add(:name => :deadVideosDamaged_envelopes_percent,
                       :indent => 1,
                       :display_heading => "Dead Videos - damaged - envelopes - percent",
                       :depends_on => [:copiesShipped_envelopes, :deadVideosDamaged_envelopes ],
                       :display_format => "%.2f%%") do |fday, lday, ndays, tdays|

               (@stats[:deadVideosDamaged_envelopes][fday] * 100.0) / @stats[:copiesShipped_envelopes][fday]

            end


            #######################################################################
            # Dead videos as percentage of copies shipped
            #######################################################################

            @stats.add(:name => :deadVideosPercent,
                       :depends_on => [:deadVideos, :copiesShipped],
                       :indent => 1,
                       :display_heading => "per Copies Shipped",
                       :display_format => "%.2f%%") do |fday, lday, ndays, tdays|

              (@stats[:deadVideos][fday] * 100.0) / @stats[:copiesShipped][fday]

            end

    #######################################################################
    # Unreturned videos, of videos shipped in this period
    #######################################################################

    @stats.add(:name => :newUnreturnedVideos,
               :display_heading => "Newly Unreturned Videos") do |fday, lday, ndays, tdays|

      Copy.count_by_sql("
          SELECT count(1)
            FROM line_items, copy, shipment
           WHERE line_items.copy_id = copy.copy_id
             AND line_items.shipments_id = shipments.shipments_id
             AND copy.status = 1
             AND ISNULL(dateBack)
             AND DATEDIFF(CURDATE(), dateOut) > 25
             AND dateOut >= '#{fday.to_s}'
             AND dateOut <= '#{lday.to_s}'")
    end

    #######################################################################
    # Unreturned as percent of shipped
    #######################################################################

    @stats.add(:name => :newUnreturnedVideosPercent,
               :depends_on => [:newUnreturnedVideos, :copiesShipped],
               :indent => 1,
               :display_heading => "% Copies Shipped",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      (@stats[:newUnreturnedVideos][fday] * 100.0) / @stats[:copiesShipped][fday]

    end

    #######################################################################
    # Total unreturned videos, as of end of period
    #######################################################################

    @stats.add(:name => :totalUnreturnedVideos,
               :display_heading => "Total Unreturned Videos") do |fday, lday, ndays, tdays|

      today = fday + (ndays.ceil) - 1

      lateVids = Copy.find_by_sql("
                     SELECT DATEDIFF('#{today.to_s}', shipments.dateOut)
                       FROM line_items, copy, shipment
                      WHERE line_items.copy_id = copy.copy_id
                        AND line_items.shipments_id = shipments.shipments_id
                        AND copy.status = 1
                        AND (ISNULL(line_items.dateBack) OR line_items.dateBack > '#{today.to_s}')
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) > 25")

      lateVids.size

    end

    #######################################################################
    # Total late videos as percent of inventory
    #######################################################################

    @stats.add(:name => :totalUnreturnedVideosPercent,
               :depends_on => [:totalUnreturnedVideos, :inventory],
               :indent => 1,
               :display_heading => "% of inventory",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|

      (@stats[:totalUnreturnedVideos][fday] * 100.0) / @stats[:inventory][fday]

    end

    #######################################################################
    # Total unreturned videos at end of period, up to 4 weeks overdue
    #######################################################################

    @stats.add(:name => :totalUnreturnedVideos2,
               :display_heading => "2 weeks or less",
               :indent => 1) do |fday, lday, ndays, tdays|

      today = fday + (ndays.ceil) - 1

      lateVids = Copy.find_by_sql("
                     SELECT DATEDIFF('#{today.to_s}', shipments.dateOut)
                       FROM line_items, copy, shipment
                      WHERE line_items.copy_id = copy.copy_id
                        AND line_items.shipments_id = shipments.shipments_id
                        AND copy.status = 1
                        AND (ISNULL(line_items.dateBack) OR line_items.dateBack > '#{today.to_s}')
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) > 25
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) <= 39")

      lateVids.size

    end

    #######################################################################
    # Total unreturned videos at end of period, 2-4 weeks overdue
    #######################################################################

    @stats.add(:name => :totalUnreturnedVideos4,
               :display_heading => "2-4 weeks",
               :indent => 1) do |fday, lday, ndays, tdays|

      today = fday + (ndays.ceil) - 1

      lateVids = Copy.find_by_sql("
                     SELECT DATEDIFF('#{today.to_s}', shipments.dateOut)
                       FROM line_items, copy, shipment
                      WHERE line_items.copy_id = copy.copy_id
                        AND line_items.shipments_id = shipments.shipments_id
                        AND copy.status = 1
                        AND (ISNULL(line_items.dateBack) OR line_items.dateBack > '#{today.to_s}')
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) > 39
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) <= 53")

      lateVids.size

    end

    #######################################################################
    # Total unreturned videos at end of period, 4-8 weeks overdue
    #######################################################################

    @stats.add(:name => :totalUnreturnedVideos8,
               :display_heading => "4-8 weeks",
               :indent => 1) do |fday, lday, ndays, tdays|

      today = fday + (ndays.ceil) - 1

      lateVids = Copy.find_by_sql("
                     SELECT DATEDIFF('#{today.to_s}', shipments.dateOut)
                       FROM line_items, copy, shipment
                      WHERE line_items.copy_id = copy.copy_id
                        AND line_items.shipments_id = shipments.shipments_id
                        AND copy.status = 1
                        AND (ISNULL(line_items.dateBack) OR line_items.dateBack > '#{today.to_s}')
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) > 53
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) <= 81")

      lateVids.size

    end

    #######################################################################
    # Total unreturned videos at end of period, 8+ weeks overdue
    #######################################################################

    @stats.add(:name => :totalUnreturnedVideos8plus,
               :display_heading => "over 8 weeks",
               :indent => 1) do |fday, lday, ndays, tdays|

      today = fday + (ndays.ceil) - 1

      lateVids = Copy.find_by_sql("
                     SELECT DATEDIFF('#{today.to_s}', shipments.dateOut)
                       FROM line_items, copy, shipment
                      WHERE line_items.copy_id = copy.copy_id
                        AND line_items.shipments_id = shipments.shipments_id
                        AND copy.status = 1
                        AND (ISNULL(line_items.dateBack) OR line_items.dateBack > '#{today.to_s}')
                        AND DATEDIFF('#{today.to_s}', shipments.dateOut) > 81")

      lateVids.size

    end

    #######################################################################
    # Wrong items sent, numeric and as percent
    #######################################################################

    # One query is used for two stats; we set up the query here as a stat, but
    # one set up to not display (no display_heading provided), and then refer
    # to it in the next two stats added (with the proper depencency)

    @stats.add(:name => :wrongItemsQuery) do |fday, lday, ndays, tdays|

      # NOTE: invoking this method on an irrelevant class, because
      #       (a) invoking it on the pure (?) virtual baseclass ActiveRecord::Base is uncool
      #       (b) as long as the SELECT uses "select as xxx", we get the columns (and thus accessors) that we need

      Copy.find_by_sql("
            SELECT count(1) as 'total',
                   count(if (wrongItemSent = 1, 1, NULL)) as 'wrong'
            FROM line_items, shipment
            WHERE  line_items.shipments_id = shipments.shipments_id
            AND dateOut >= \"#{fday.to_s}\"
            AND dateOut <= \"#{lday.to_s}\"")
    end

    @stats.add(:name => :wrongItems,
               :depends_on => [:wrongItemsQuery],
               :display_heading => "Wrong shipments") do |fday, lday, ndays, tdays|

      @stats[:wrongItemsQuery][fday][0].wrong.to_f

    end

    @stats.add(:name => :wrongItemsPercent,
               :depends_on => [:wrongItemsQuery],
               :indent => 1,
               :display_heading => "as percent",
               :display_format => "%.2f%%") do |fday, lday, ndays, tdays|

      100.0 * @stats[:wrongItemsQuery][fday][0].wrong.to_f / @stats[:wrongItemsQuery][fday][0].total.to_f;

    end

    #######################################################################
    # Shipping delay on orders of size 1
    #######################################################################

    # As above, we use an undisplayed stat to do the query, and have a bunch
    # of other stats that depend on the results of that one for display

    @stats.add(:name => :custDelay1) do |fday, lday, ndays, tdays|

      Copy.find_by_sql("
               SELECT
               a1 / items as 'p1',
               a2 / items as 'p2',
               a4 / items as 'p4',
               a8 / items as 'p8',
               a16 / items as 'p16',
               a16p / items as 'p16plus',
               notshipped / items as 'not shipped %'
               FROM
                ( SELECT
                   count(items) as 'items',
                   count(if(first <= 1, 1, NULL)) as 'a1',
                   count(if(first <= 2, 1, NULL)) as 'a2',
                   count(if(first <= 4, 1, NULL)) as 'a4',
                   count(if(first <= 8, 1, NULL)) as 'a8',
                   count(if(first <= 16, 1, NULL)) as 'a16',
                   count(if(first >  16, 1, NULL)) as 'a16p',
                   count(if(ISNULL(first), 1, NULL)) as 'notshipped'
                   FROM
                       (SELECT order_id,  orderDate, count(*) as 'items', min(delta) as 'first', max(delta) as 'last'
                        FROM (SELECT *, TO_DAYS(dateOut) - TO_DAYS(orderDate) as delta
                              FROM ( SELECT orders.order_id, orderDate, dateOut, line_items.shipments_id
                                     FROM line_items, orders
                                     LEFT JOIN shipment on line_items.shipments_id = shipments.shipments_id
                                     WHERE line_items.order_id = orders.order_id
                                     AND line_items.live = 1
                                     AND orderDate >= \"#{fday.to_s}\"
                                     AND orderDate <= \"#{lday.to_s}\")
                              as dates_on_each_item)
                       as delay_on_each_item
                       GROUP BY order_id)
               as min_max_delay_on_each_order where items = 1)
           as binned_delays");
    end

    # Empty non-indented display line

    @stats.add(:name => :custDelay1Display,
               :display_heading => "Delays on shipments (order size = 1)") do |fday, lday, ndays, tdays|
      nil
    end

    @stats.add(:name => :custDelay1d1,
               :depends_on => [:custDelay1],
               :indent => 1,
               :display_heading => "1 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay1][fday][0].p1.to_f * 100.0
    end

    @stats.add(:name => :custDelay1d2,
               :depends_on => [:custDelay1],
               :indent => 1,
               :display_heading => "2 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay1][fday][0].p2.to_f * 100.0
    end

    @stats.add(:name => :custDelay1d4,
               :depends_on => [:custDelay1],
               :indent => 1,
               :display_heading => "4 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay1][fday][0].p4.to_f * 100.0
    end

    @stats.add(:name => :custDelay1d8,
               :depends_on => [:custDelay1],
               :indent => 1,
               :display_heading => "8 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay1][fday][0].p8.to_f * 100.0
    end

    @stats.add(:name => :custDelay1d16,
               :depends_on => [:custDelay1],
               :indent => 1,
               :display_heading => "16 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay1][fday][0].p16.to_f * 100.0
    end

    #######################################################################
    # Shipping delay on orders of size 2
    #######################################################################

    # As above, we use an undisplayed stat to do the query, and have a bunch
    # of other stats that depend on the results of that one for display

    @stats.add(:name => :custDelay2) do |fday, lday, ndays, tdays|

      Copy.find_by_sql("
               SELECT
               a1 / items as 'p1',
               a2 / items as 'p2',
               a4 / items as 'p4',
               a8 / items as 'p8',
               a16 / items as 'p16',
               a16p / items as 'p16plus',
               notshipped / items as 'not shipped %'
               FROM
                ( SELECT
                   count(items) as 'items',
                   count(if(first <= 1, 1, NULL)) as 'a1',
                   count(if(first <= 2, 1, NULL)) as 'a2',
                   count(if(first <= 4, 1, NULL)) as 'a4',
                   count(if(first <= 8, 1, NULL)) as 'a8',
                   count(if(first <= 16, 1, NULL)) as 'a16',
                   count(if(first >  16, 1, NULL)) as 'a16p',
                   count(if(ISNULL(first), 1, NULL)) as 'notshipped'
                   FROM
                       (SELECT order_id,  orderDate, count(*) as 'items', min(delta) as 'first', max(delta) as 'last'
                        FROM (SELECT *, TO_DAYS(dateOut) - TO_DAYS(orderDate) as delta
                              FROM ( SELECT orders.order_id, orderDate, dateOut, line_items.shipments_id
                                     FROM line_items, orders
                                     LEFT JOIN shipment on line_items.shipments_id = shipments.shipments_id
                                     WHERE line_items.order_id = orders.order_id
                                     AND line_items.live = 1
                                     AND orderDate >= \"#{fday.to_s}\"
                                     AND orderDate <= \"#{lday.to_s}\")
                              as dates_on_each_item)
                       as delay_on_each_item
                       GROUP BY order_id)
               as min_max_delay_on_each_order where items = 2)
           as binned_delays");
    end

    # Empty non-indented display line

    @stats.add(:name => :custDelay2Display,
               :display_heading => "Delays on shipments (order size = 2)") do |fday, lday, ndays, tdays|
      nil
    end

    @stats.add(:name => :custDelay2d1,
               :depends_on => [:custDelay2],
               :indent => 1,
               :display_heading => "1 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay2][fday][0].p1.to_f * 100.0
    end

    @stats.add(:name => :custDelay2d2,
               :depends_on => [:custDelay2],
               :indent => 1,
               :display_heading => "2 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay2][fday][0].p2.to_f * 100.0
    end

    @stats.add(:name => :custDelay2d4,
               :depends_on => [:custDelay2],
               :indent => 1,
               :display_heading => "4 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay2][fday][0].p4.to_f * 100.0
    end

    @stats.add(:name => :custDelay2d8,
               :depends_on => [:custDelay2],
               :indent => 1,
               :display_heading => "8 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay2][fday][0].p8.to_f * 100.0
    end

    @stats.add(:name => :custDelay2d16,
               :depends_on => [:custDelay2],
               :indent => 1,
               :display_heading => "16 day",
               :display_format => "%.1f%%") do |fday, lday, ndays, tdays|
      @stats[:custDelay2][fday][0].p16.to_f * 100.0
    end

    #######################################################################
    # Gnucash derived stats
    #######################################################################

    # As above, we use an undisplayed stat to do the query, and have a bunch
    # of other stats that depend on the results of that one for display

    @stats.add(:name => :gnucash) do |fday, lday, ndays, tdays|

      Copy.find_by_sql("
            SELECT
                   sum(if (category='Videos', amount, 0.0)) as 'videos',
                   sum(if (category='rentals', amount, 0.0)) as 'rentalIncome',
                   sum(if (category='Expenses', amount, 0.0)) as 'miscExpenses',
                   sum(if (category='Depreciation Expense - IT', amount, 0.0)) as 'depreciationIT',
                   sum(if (category='Depreciation Expense - Videos', amount, 0.0)) as 'depreciationVideos',
                   sum(if (category='Facilities', amount, 0.0)) as 'facilities',
                   sum(if (category='Postage', amount, 0.0)) as 'postage',
                   sum(if (category='MerchantAccountFees', amount, 0.0)) as 'merchAcctFees',
                   sum(if (category='Shipping Supplies', amount, 0.0)) as 'materials',
                   sum(if (category='ShippingLabor', amount, 0.0)) as 'shippingLabor',
                   sum(if (category='IT', amount, 0.0)) as 'it',
                   sum(if (category='Interest Expense', amount, 0.0)) as 'interest',
                   sum(if (category='OfficeLabor', amount, 0.0)) as 'officeLabor',
                   sum(if (category='Legal', amount, 0.0)) as 'legal',
                   sum(if (category='Marketing', amount, 0.0)) as 'marketing'
              FROM gnucash
             WHERE date >= \"#{fday.to_s}\"
               AND date <= \"#{lday.to_s}\"")
    end

    #######################################################################
    # Rental Income
    #######################################################################

    @stats.add(:name => :gnuRentalIncome,
               :depends_on => [:gnucash],
               :display_heading => "Gnucash Rental Income",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      @stats[:gnucash][fday][0].rentalIncome.to_f.abs

    end

    #######################################################################
    # Cost of Sales
    #######################################################################

    @stats.add(:name => :gnuShipping,
               :depends_on => [:gnucash],
               :display_heading => "Cost of Sales",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      @stats[:gnucash][fday][0].merchAcctFees.to_f +
      @stats[:gnucash][fday][0].postage.to_f +
      @stats[:gnucash][fday][0].shippingLabor.to_f +
      @stats[:gnucash][fday][0].materials.to_f
    end

            @stats.add(:name => :merchAcctFees,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "merch Acct Fees",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].merchAcctFees.to_f

            end

            @stats.add(:name => :gnuShippingPostage,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "postage",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].postage.to_f

            end

            @stats.add(:name => :gnuShippingLabor,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "shipping labor",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].shippingLabor.to_f

            end

            @stats.add(:name => :gnuShippingMaterials,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "materials",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].materials.to_f

            end


    #######################################################################
    # Operating expenses
    #######################################################################

    @stats.add(:name => :gnuTotalOpExpenses,
               :depends_on => [:gnucash],
               :display_heading => "Operating Expenses",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

        @stats[:gnucash][fday][0].legal.to_f +
        @stats[:gnucash][fday][0].marketing.to_f +
        @stats[:gnucash][fday][0].it.to_f +
        @stats[:gnucash][fday][0].officeLabor.to_f +
        @stats[:gnucash][fday][0].facilities.to_f +
        @stats[:gnucash][fday][0].depreciationVideos.to_f +
        @stats[:gnucash][fday][0].miscExpenses.to_f

    end


            @stats.add(:name => :gnuITExpenses,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "IT",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].it.to_f

            end

            @stats.add(:name => :gnuInterest,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "interest",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].interest.to_f

            end

            @stats.add(:name => :gnuFacilities,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "facilities",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].facilities.to_f

            end

            @stats.add(:name => :gnuLegalExpenses,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "legal",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].legal.to_f

            end

            @stats.add(:name => :gnuAdExpenses,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "marketing",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].marketing.to_f

            end


            @stats.add(:name => :gnuOfficeLabor,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "office labor",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].officeLabor.to_f

            end


            @stats.add(:name => :gnuVideoDepreciation,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "video depreciation",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].depreciationVideos.to_f

            end

            @stats.add(:name => :gnuMiscExpenses,
                       :depends_on => [:gnucash],
                       :indent => 1,
                       :display_heading => "misc",
                       :display_format => "$%.0f") do |fday, lday, ndays, tdays|

              @stats[:gnucash][fday][0].miscExpenses.to_f

            end

    #######################################################################
    # Total Expenses
    #######################################################################

    @stats.add(:name => :gnuTotalExpenses,
               :depends_on => [:gnuTotalOpExpenses, :gnuShipping],
               :display_heading => "Total Expenses",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      @stats[:gnuTotalOpExpenses][fday] + @stats[:gnuShipping][fday]

    end


    #######################################################################
    # Labor / unit shipped
    #######################################################################

    @stats.add(:name => :laborPerShipped,
               :depends_on => [:gnuShippingLabor, :copiesShipped],
               :display_heading => "Labor per Copy Shipped",
               :display_format => "$%.2f") do |fday, lday, ndays, tdays|

      @stats[:gnuShippingLabor][fday].to_f / @stats[:copiesShipped][fday].to_f

    end

    #######################################################################
    # Cost of new videos
    #######################################################################

    @stats.add(:name => :gnuVideoPurchase,
               :depends_on => [:gnucash],
               :display_heading => "Cost of New Videos",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      @stats[:gnucash][fday][0].videos.to_f

    end

    #######################################################################
    # Average cost of each new copy
    #######################################################################

    @stats.add(:name => :costPerCopy,
               :depends_on => [:gnuVideoPurchase, :inventory],
               :indent => 1,
               :display_heading => "each copy",
               :display_format => "$%.2f") do |fday, lday, ndays, tdays, prev|

      if (prev)
        @stats[:gnuVideoPurchase][fday] / (@stats[:inventory][fday] - @stats[:inventory][prev])
      else
        nil
      end

    end

    #######################################################################
    # Dead video replacement costs
    #######################################################################

    @stats.add(:name => :vidReplacement,
               :depends_on => [:deadVideos, :costPerCopy],
               :display_heading => "Dead video replacement cost",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      if (@stats[:costPerCopy][fday])
        @stats[:deadVideos][fday] * @stats[:costPerCopy][fday]
      else
        nil
      end

    end


    #######################################################################
    # Operating profit
    #######################################################################

    @stats.add(:name => :gnuProfit,
               :depends_on => [:gnuTotalExpenses, :vidReplacement, :gnuRentalIncome],
               :display_heading => "Operating Profit",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      if (@stats[:vidReplacement][fday])
        @stats[:gnuRentalIncome][fday] - (@stats[:gnuTotalExpenses][fday] + @stats[:vidReplacement][fday])
      else
        @stats[:gnuRentalIncome][fday] - @stats[:gnuTotalExpenses][fday]
      end

    end

    #######################################################################
    # Profit as percent of revenue
    #######################################################################

    @stats.add(:name => :gnuProfitPercent,
               :depends_on => [:gnuProfit, :gnuRentalIncome],
               :indent => 1,
               :display_heading => "as percent of revenue",
               :display_format => "%.0f%%") do |fday, lday, ndays, tdays|

      (@stats[:gnuProfit][fday] / @stats[:gnuRentalIncome][fday]) * 100.0

    end

    #######################################################################
    # Bottom line
    #######################################################################

    @stats.add(:name => :gnuBottomLine,
               :depends_on => [:gnuTotalExpenses, :gnuVideoPurchase, :gnuRentalIncome],
               :display_heading => "Bottom Line",
               :display_format => "$%.0f") do |fday, lday, ndays, tdays|

      @stats[:gnuRentalIncome][fday] - (@stats[:gnuTotalExpenses][fday] + @stats[:gnuVideoPurchase][fday])

    end

    #######################################################################
    # revenue per category
    #######################################################################

    @stats.add(:display_heading => "rental revenue from cats",
               :display_format => "") do |x|
    end

    cats = Category.find(:all,
                         :readonly => true,
                         :conditions => "parent_id = 0")
    cats.sort_by{|cat| cat.name}.each do | cc |

      @stats.add(  # :name => :"revenuecat#{cc.category_id}",
                 :depends_on => [:revenuerental],
                 :indent => 1,
                 :display_heading => "rental revenue from cat " + cc.name,
                 :display_format => "%02.0f\%") do |fday, lday, ndays, tdays|


        Category.find(:all,
                      :readonly => true,
                      :select => "sum(price) as total",
                      :joins => "LEFT JOIN titleCat  ON categories.category_id = titleCat.category_id
                                 LEFT JOIN line_items  ON titleCat.title_id = line_items.title_id
                                 LEFT JOIN orders ON line_items.order_id = orders.order_id",
                      :conditions => "line_items.live = 1
                                 AND (categories.category_id = #{cc.category_id} OR categories.parent_id = #{cc.category_id})
                                 AND orders.orderDate >= \"#{fday.to_s}\"
                                 AND orders.orderDate <= \"#{lday.to_s}\" 
                                 AND #{Order.charge_type_sql(:rental)}"
                                   )[0].total.to_f  / @stats[:revenuerental][fday] * 100


      end
    end

#     #######################################################################
#     # conversion per category
#     #######################################################################

#     @stats.add(:display_heading => "conversions per category",
#                :display_format => "") do |fday, lday, ndays, tdays|
#     end

#     cats = Category.find(:all,
#                          :readonly => true,
#                          :conditions => "parent_id = 108 OR parent_id = 115")
#     cats.sort_by{|cat|cat.full_name}.each do | cc |
      
#       @stats.add(:indent => 1,
#                  :display_heading => "conversions : " + cc.full_name,
#                  :display_format => "%02.5f\%") do |fday, lday, ndays, tdays|
#         Order.orders_from_cat(fday, lday, cc.category_id) / 
#           ( Customer.STATS_num_visitors_cat(fday, lday, cc.category_id, true, true) * 1.0)
#       end
      
#       @stats.add(:indent => 2,
#                  :display_heading => "visits : " + cc.full_name,
#                  :display_format => "%i") do |fday, lday, ndays, tdays|
#         Customer.STATS_num_visitors_cat(fday, lday, cc.category_id, true, true) 
#       end
      
#       @stats.add(:indent => 2,
#                  :display_heading => "orders : " + cc.full_name,
#                  :display_format => "%i") do |fday, lday, ndays, tdays|
#         Order.orders_from_cat(fday, lday, cc.category_id)
#       end
      
#     end


    @form_options, params, @data_format,  @data_rows, @period = @stats.return_state()
    @period        = (params[:p] =~ /^(year|quarter|2month|month|week|[0-9]+)$/) ? params[:p] : "month"
    @num_intervals = (params[:n] =~ /^[0-9]+$/) ? params[:n] : "6"
    @confidence    = (params[:c] =~ /^(80|90|95|99)$/) ? params[:c] : "95"

  end


  def ab_test
    

    #######################################################################
    # Create a stats object, and populate it with the statistics we want to
    # collect and calculate; the stats object is then displayed in the view
    # via a call to @stats.display()
    #######################################################################


    # find all the test results
    #
#    raise params.inspect
    @tests = AbTest.find(:all, :order =>"active desc, ab_test_id")

    @result_tests = []
    if request.post?
      (params["tests"] || {}).keys.each do |test_name|
        @result_tests << AbTest.find_by_name(test_name)
      end
    end
  end # def ab_test

end


class Stats
  def initialize(params, period, nPeriods)
    @params = params
    @period = period

    @stats = Hash.new
    @args = Hash.new
    @order = Array.new
    @uncomputed = Array.new

    # Create the proc object to call for iterating through the dates

    case period
    when "year" then
      @date_iter = lambda { |calc_block| Date.today.each_prev_year(nPeriods, &calc_block) }
    when "quarter" then
      @date_iter = lambda { |calc_block| Date.today.each_prev_quarter(nPeriods, &calc_block) }
    when "2month" then
      @date_iter = lambda { |calc_block| Date.today.each_prev_2month(nPeriods, &calc_block) }
    when "week" then
      @date_iter = lambda { |calc_block| Date.today.each_prev_week(nPeriods, &calc_block) }
    when /^[0-9]+$/
      @date_iter = lambda { |calc_block| Date.today.each_prev_ndays(period.to_i, nPeriods, &calc_block) }
    else
      @date_iter = lambda { |calc_block| Date.today.each_prev_month(nPeriods, &calc_block) }
    end

  end

  @@allowed_args = [:name, :depends_on, :indent, :display_heading, :display_format, :dh,
                   :controller, :action, :action_args, :per_day, :growth ]

  # Add a statistic to compute
  def add(args, &block)
    
    # Make sure all args are valid (helps us catch typos)
    if ((args.keys - @@allowed_args).size > 0)
      throw "Unsupported arguments #{(args.keys - @@allowed_args).inspect}"
    end
    
    args[:indent] ||= 0
    
    # to make it easier to call this func: two params are now optional
    #   * :name           - build from display_heading
    #   * :display_format - defaults to "%d"
    args[:display_heading] ||= args[:dh]
    args[:name] ||= args[:display_heading].to_sym_clean
    args[:display_format] ||= "%d"
    
    # No dups allowed
    if (@order.include?(args[:name]))
      throw "Duplicate stat #{args[:name]} in #{args.inspect}"
    end
    
    @uncomputed << [args, block]
    @args[args[:name]] = args
    @stats[args[:name]] = Hash.new
    @order << args[:name]
    
    if  args[:per_day]
      child_args = { }
      child_args[:display_heading] =  (args[:display_heading]  + " / day" )
      child_args[:display_format] = args[:display_format]
      child_args[:depends_on] = [ args[:name] ]
      child_args[:indent] = args[:indent] + 1
      
      add(child_args) do  |fday, lday, ndays, tdays|
        @stats[args[:name]][fday] / ndays  
      end
    end
    
    if args[:growth]
       per_day_name = args[:display_heading]  + " / day"
      per_day_sym = per_day_name.to_sym_clean
       child_args = { }
       child_args[:display_heading] =  args[:display_heading]  + " growth"
       child_args[:display_format] = "%.1f%%"
       child_args[:depends_on] = [ per_day_name.to_sym_clean ]
       child_args[:indent] = args[:indent] + 1
     
       add(child_args) do  |fday, lday, ndays, tdays, prev|
         if (prev)
#           raise "#{@stats[per_day_sym][fday]} ; #{@stats[per_day_sym][prev]} ; #{per_day_sym.inspect}"
           ((@stats[per_day_sym][fday] - @stats[per_day_sym][prev]) * 100.0) / @stats[per_day_sym][prev]
         end
       end
     end
    
  end

  # Lookup a particular statistic
  def [](name)
    return @stats[name]
  end

  def return_state

    # Do all the math
    compute()

    # Use old display code for now, set up data for that; current format
    # @stats = { :name => hash_of_stats }
    # @args = { :name => { :display_heading => "Heading", :display_format => "%format" } }
    # Need format
    # [ [ "Heading", hash_of_stats, "%format" ] ]

    displayData = Array.new

    @order.each do |name|

      # Only display if display requested and item has a heading to display
      next if @params[name] != 'on'
      next if @args[name][:display_heading].nil?

      heading = @args[name][:display_heading]
      if (@args[name][:indent])
        heading = ("*" * @args[name][:indent] )+ " " + heading
      end
      hash = @stats[name]
      format = @args[name][:display_format]

      displayData << [ heading, hash, format ]

    end
    [ @order, @params, @args, displayData, @period ]

  end

  # Compute all statistics that have been added
  def compute()

    # Remove all the items that are neither to be displayed or required to
    # compute something else that is to be displayed

    required = compute_required()

    @uncomputed = @uncomputed.select { |args, block| required.include?(args[:name]) }

    # Keep looping through the uncomputed until we finish them all or stop
    # making progress

    progress = true

    while(progress)

      progress = false

      # Loop through all uncomputed

      cannot_compute_yet = Array.new

      @uncomputed.each do |args, calc_block|

        # See if all the dependencies are completed for this one, if not keep
        # it for next loop

        if (args[:depends_on] && args[:depends_on].select { |d| @stats[d].size > 0 }.size < args[:depends_on].size)
          cannot_compute_yet << [args, calc_block]
          next
        end

        # Create function to be passed to the date iterator; we set up a
        # "previous period" value here that we pass up
        prev = nil
        calc_function = lambda do |fday, lday, ndays, tdays|
          @stats[args[:name]][fday] = calc_block.call(fday, lday, ndays, tdays, prev)
          prev = fday
        end

        # Call the above function for each date we're interested in (set up else where)
        @date_iter.call(calc_function)

        # We've made progress...
        progress = true

      end

      @uncomputed = cannot_compute_yet

    end

    if (@uncomputed.size > 0)
      throw "Did not finish computing, some dependencies not met: #{@uncomputed.collect { |args, block| args[:name] }.inspect }"
    end

  end

  def compute_prereqs(name)
    if (@args[name].nil?)
      throw "Found dependency on #{name.inspect}, but #{name.inspect} does not exist in #{ @args.keys.inspect}"
    end
    prereqs = Array.new
    up1 = @args[name][:depends_on].to_array
    uprest = Array.new
    @args[name][:depends_on].to_array.each do |prereq_name|
      uprest += compute_prereqs(prereq_name)
    end
    return up1 + uprest
  end

  def compute_required()
    required = Array.new
    @order.each do |name|
      if (@params[name] == 'on')
        required << name
        required += compute_prereqs(name)
      end
    end
    return required
  end

end

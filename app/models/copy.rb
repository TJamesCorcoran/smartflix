class Copy < ActiveRecord::Base
  self.primary_key = "copy_id"
  attr_protected # <-- blank means total access

  belongs_to :product
  belongs_to :death_type
  has_many   :death_logs
  has_many   :line_items
  has_one    :potential_item

  scope :good, lambda { |product| { :conditions => "status = 1 and product_id = #{product.product_id}"}}
  scope :good_any, :conditions => "status = 1"

  scope :in_stock,  :conditions => "inStock = 1"
  scope :out_stock,  :conditions => "inStock = 0"
  scope :lost_unpaid,  :conditions => "death_type_id = #{DeathLog::DEATH_LOST_BY_CUST_UNPAID}"

  delegate :name, :to => :product

  #----------
  # product stuff
  #
  def precond()    product.andand.precond  end
  def any_postconds?()    product.andand.any_postconds?  end
  def any_preconds?()    product.andand.any_preconds?  end

  
  #----------
  # line item / shipments stuff
  #
  def times_out
    line_items.select { |li| li.shipment && li.dateBack.nil?}.size
  end

  def last_line_item
    line_items.sort_by { |li| li.shipment.dateOut }.last
  end

  def line_items_out
    line_items.select { |x| ! x.shipment.nil? && x.dateBack.nil? }
  end

  def line_items_out_last
    line_items_out.sort_by { |li| li.shipment.dateOut }.last
  end

  def last_out 
    last_line_item.dateOut
  end

  #----------
  # shipping: in / out of stock, etc.
  #
  def here_and_good?() (status == 1) && (inStock == 1) end

  def reserve()      update_attributes(:tmpReserve => true)  end
  def unreserve()    update_attributes(:tmpReserve => false)  end
  
  def remove_from_stock
    raise "copy #{copy_id} already out of stock" if (inStock == 0)
    update_attributes(:inStock => false)
  end

  def expect_in_drawer?
    status == 1 && inStock == 1
  end

  def returnable_to_stock?
    DeathLog::AUTOMATICALLY_MARK_AS_HEALED.include?(death_type_id)
  end

  def thought_lost?
    [ DeathLog::DEATH_LOST_IN_TRANSIT,
      DeathLog::DEATH_SOLD,
      DeathLog::DEATH_LOST_IN_HOUSE].include?(death_type_id)
  end

  def unpaid?
    [ DeathLog::DEATH_LOST_BY_CUST_UNPAID].include?(death_type_id)
  end


  def return_to_stock
    # bring back to life if it's that kind of death (e.g. "went to wrong customer", etc.)
    # note that the update_attributes() call will save this to the db

    if (status != 1) && returnable_to_stock?
      mark_dead(DeathLog::DEATH_NOT_DEAD, "back to life via returns process") 
    end

    line_items_out_last.andand.update_attributes(:dateBack => Date.today)
    update_attributes(:inStock => true)
  end
  
  def return_to_stock_multiple(leave_last_one_out = true)
    count = 0
    lis = line_items_out
    lis.sort! { |lia, lib| lia.shipment.dateOut <=> lib.shipment.dateOut}.pop if leave_last_one_out
    lis.each do |li|
      li.dateBack = Date.today
      li.save
      count += 1
    end
    update_attributes(:inStock => line_items_out.empty? )
    return count
  end

  # lost by customer UNPAID
  #
  def self.candidates_for_lbcu
    Copy.out_stock.good_any.select { |copy| 
      li = copy.last_line_item
      li.dateOut < (Date.today << 12) ||
      li.customer.valid_cards.empty? 
    }
  end


  def self.good_between_ids(start_id, end_id)
    Copy.connection.select_values("SELECT copy_id
                                  FROM copies 
                                  WHERE copy_id >= #{start_id}
                                  AND copy_id < #{end_id}
                                  AND inStock = 1
                                  AND status = 1
                                  ORDER BY copy_id").map(&:to_i)
  end

  def self.number_good_between_ids(start_id, end_id)
    Copy.connection.select_values("SELECT COUNT(1)
                                  FROM copies 
                                  WHERE copy_id > #{start_id}
                                  AND copy_id < #{end_id}
                                  AND inStock = 1
                                  AND status = 1")
  end

  # used in inventory process
  def self.next_instock_inrange(begin_id, end_id)
    Copy.connection.select_value("SELECT min(copy_id) 
                                  FROM  copies 
                                  WHERE copy_id > #{begin_id}
                                  AND   copy_id <= #{end_id} 
                                  AND   status  = 1
                                  AND   inStock = 1").to_i
  end

  #----------
  # inventories
  #----------
  has_many :inventories,  :finder_sql => proc { "select * from inventories where startID <= #{copy_id} AND endID >= #{copy_id}"}

  def last_inventory
    inventories.max_by(&:inventoryDate)
  end
  
  #----------
  # death / status / life cycle stuff
  #----------

  #-----
  # get
  #-----
  def good?() status == 1 end
  def live?()    status == 1  end

  def most_recent_death
    return nil if death_logs.nil?
    death_logs.sort_by { |dl| dl.editDate }.last
  end

  def complex_status()
    if (0 == status) then return "dead" end
    if (due_back.nil?) then return "delayed" else return "live" end
  end

  def lost_unpaid?() death_type_id == DeathLog::DEATH_LOST_BY_CUST_UNPAID  end

  def lost_noaddr?() death_type_id == DeathLog::DEATH_LOST_BY_CUST_NOADDR  end

  #-----
  # set
  #-----

  def mark_as_scratched(comment = "")
    mark_dead(DeathLog::DEATH_DAMAGED, comment)
  end

  def mark_as_lost_by_cust_paid(comment = "", line_item = nil)
    mark_dead(DeathLog::DEATH_SOLD, comment)
  end

  def mark_as_lost_by_cust_unpaid(comment = "", line_item = nil)
    mark_dead(DeathLog::DEATH_LOST_BY_CUST_UNPAID, comment)
  end

  def mark_as_lost_in_house(comment = "")
    mark_dead(DeathLog::DEATH_LOST_IN_HOUSE, comment)
  end

  def mark_lost_noaddr(comment = "")
    mark_dead(DeathLog::DEATH_LOST_BY_CUST_NOADDR, comment)
  end

  def mark_live(note = nil)
    mark_dead(DeathLog::DEATH_NOT_DEAD, note)
  end

  def mark_dead(deathtype, note)

    # Update our status
    status = (deathtype == DeathLog::DEATH_NOT_DEAD) ? 1:0
    self.update_attributes(:status => status, :death_type_id => deathtype, :deathDATE => Date.today)

    # Insert a related death note in deathLog
    DeathLog.create(:copy_id => self.id, :newDeathType => deathtype, :editDate => Date.today, :note => note)
  end

  #----------
  # ??
  #----------


  # how many days until this copy comes back to us?
  #
  # dead?  out for a real long time?  --> nil
  # instock                           --> 0    (days)
  # due back soon?                    --> 1-20 (days)
  #
  def due_back()
    if (1 != status)
      return nil
    end
    if (1 == inStock)
      return 0
    else
      last_li = LineItem.for_copy_in_field(self).last
      if last_li.nil? # "can't happen" case - not in stock, yet never in a line item either.  WT* ?
        return nil
      end
      days_out = (Date.today() - last_li.shipment.dateOut).to_i
      if (days_out < 21)
        return (21 - days_out)
      elsif (days_out < 42)
        return 20
      else
        return 1000
      end
    end
  end

  def find_next_free_copy_id(employee_id)
    # hack to let Suz
    low = 18 * 1000
    if (employee_id == 2) then low = 19 * 1000 end
    ids = ActiveRecord::Base.connection.select_values(ActiveRecord::Base.send(:sanitize_sql_array,[ "select copy_id from copies where copy_id >= #{low} order by copy_id" ]))
    last = low - 1
    ids.each do |id|
      id = id.to_i
      if (id > (last + 1)) then return (last + 1) end
      last = id
    end
    return last + 1
  end

  # If we're creating a new copy, then presumably we ordered it from the vendor at some pt.
  # If we can't find the vendor order, then we must have failed to note it when we placed it.
  # Create the vendor order now.
  #
  def create_fake_order()
    
    
    if product.inventory_ordered.nil?
      product.inventory_ordered = InventoryOrdered.new(:quant_dvd => 0)
      product.inventory_ordered.save
    end
    
    product.inventory_ordered.quant_dvd = 1
    orderdate = Date.today - 7
    product.save
    vol = VendorOrderLog.find(:all, :conditions => "product_id = #{product.product_id} AND orderDate = '#{orderdate}' AND quant > 0")[0]
    if (vol.nil?) 
      vol = VendorOrderLog.new(:product_id => product.product_id, :orderDate => orderdate, :purchaser_id=> Purchaser.find_by_name_first("smartflix").andand.id) 
    end
    # quant is positive, bc the number on order has increased
    vol.quant += 1
    vol.save
    
    
  end

  def before_save
    # only if this is a new copy, do the following
    return if (! id.nil?) || product.nil? 
    
    if (! desired_copy_id.nil?) then self.id = desired_copy_id end
    
    # If there are no outstanding orders, then engage in historical revisionism and create some
    if (product.inventory_ordered.nil? || 0 == product.inventory_ordered.quant_dvd) then create_fake_order  end
    
    # note this arrival in the vol and io
    vol = VendorOrderLog.find(:all, :conditions => "product_id = #{product.product_id} AND orderDate = '#{Date.today}' AND quant < 0")[0]
    if (vol.nil?)
      vol = VendorOrderLog.new(:product_id => self.product.product_id, :orderDate => Date.today, :purchaser_id=> Purchaser.find_by_name_first("smartflix").andand.id)
    end
    # quant is negative, bc the number on order has decreased
    vol.quant -= 1
    vol.save
    
    io = self.product.inventory_ordered
    io.quant_dvd -= 1
    io.save
  end


  #----------
  # clean_delete() -
  #
  #    Delete this copy, and keep the inventory_ordered and vendor_order_log in synch.
  #    Return false if we are unable to do that.
  #    Return true otherwise.
  #
  def clean_delete(override_li_test_P = false)
    return "no product for this copy" if  product.nil?
    vols = product.vendor_order_logs
    return "no vendor_order_log entries to cleanup" if vols.empty?
    last_change = vols.sort_by { |vol| vol.orderDate }.reverse[0]
    return "last vendor_order_log entry was > 0" if last_change.quant > 0

    io = product.inventory_ordered
    return "no inventory_ordered to cleanup" if io.nil?

    return "line items exist for this copy" if !override_li_test_P && ! line_items.empty?

    last_change.quant += 1
    last_change.save
    last_change.destroy if (last_change.quant == 0)

    io.quant_dvd += 1
    io.save

    self.destroy

    return true
  end

  #----------
  # things we might charge a customer
  #----------  
  def late_price()         product.late_price  end

  def replacement_price()  
    product.replacement_price  
  end


  def value()              product.value  end
  def boxP()
    value > 1 || product.vendor.vendor_mood_id == 1 || ! product.handout.andand.empty_is_nil.nil?
  end

  #----------
  # sticker stuff  
  #
  def sticker_id
    Copy.id_to_sticker(id).strip
  end


  def self.find_by_sticker(stid)
    Copy.find(Copy.sticker_to_id(stid))
  end
  
  def self.sticker_to_id(stid)
    first = stid.upcase[0,stid.size - 4]
    last = stid[-4,4]
    raise "sticker id '#{stid}' looks invalid" if last.nil? || ! last.is_all_numer
    raise "more than 1 alpha character in sticker ID not implemented" if first.size > 1
    first = ((first.to_i != 0) ? 
             first :
             " ABCDEFGHIJKLMNOPQRSTUVWXYZ".index(first).to_s)
    (first + last).to_i
  end

  def self.id_to_sticker(id)
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ"[id / 10000,1] + sprintf("%04i", (id % 10000))    
  end
  
  def self.unreturned
    LineItem.deeply_overdue.map{ |li| li.copy }.select { |cc| cc.status == 1 && cc.mediaformat > 1 }
  end

  def self.overdue_internal(countP = true, late_field = :lateMsg2Sent, days_since_late = 14)
    # NOTE: we could check for deathType != DEATH_SOLD, but
    # we check for status = 1, which accomplishes the same thing
    #
    select_results = countP ? "count(1) as cnt" : "DISTINCT c.*"
    ret = Copy.find_by_sql("SELECT #{select_results}
                        FROM shipments sh, copies c, orders co, credit_cards cc, line_items li
                        WHERE li.shipment_id = sh.shipment_id
                        AND ISNULL(dateBack)
                        AND li.copy_id = c.copy_id
                        AND status = 1
                        AND mediaFormat = 2
                        AND ! ISNULL(#{late_field})
                        AND ( to_days(#{late_field}) + #{days_since_late} < to_days(now()))
                        AND li.orderID = co.orderID
                        AND co.customer_id = cc.customer_id
                        ORDER BY li.copy_id")
    ret = ret[0].cnt if countP
  end

  # returns the number of copies
  def self.unreturned_and_billable_for_overdue()
    overdue_internal(true, :lateMsg1Sent, 0)
  end

  def self.ERRORCHECK_in_and_out_not_one
    Copy.find_by_sql("SELECT * 
                      FROM  (
                          SELECT copy_id 
                          FROM (
                          SELECT line_items.copy_id, count(IF (ISNULL(dateBack), 1, NULL)) as 'simul rentals', inStock, count(IF (ISNULL(dateBack), 1, NULL)) + inStock as 'total' 
                              FROM line_items, shipments, copies
                              WHERE line_items.shipment_id = shipments.shipment_id 
                              AND copies.copy_id = line_items.copy_id 
                              AND copies.death_type_id != 5 
                              AND actionable = 1
                              GROUP BY copy_id) copyid_to_totals 
                          WHERE total !=1) problematic_copyids 
                      LEFT JOIN copies
                      ON problematic_copyids.copy_id = copies.copy_id")  
  end
  
  def self.ERRORCHECK_lost_and_actually_here
    ret = Copy.find_by_sql("SELECT * 
                            FROM copies 
                            WHERE inStock = 1 
                            AND death_type_id in (#{DeathLog::SHOULD_NOT_FIND_IN_HOUSE.join(',')})")
    
  end
  
  def self.DATAMINE_unreturned_and_billable_for_replacement(days_since_late = 14)
    overdue_internal(false, :lateMsg2Sent, days_since_late).sort_by { |cc| cc.id }
  end

  #----------------------------------------
  # CLASS METHODS
  #
  def self.min_id() 
    Copy.connection.select_value("select MIN(copy_id) from copies where mediaformat = 2 ").to_i
  end

  def self.max_id() 
    Copy.connection.select_value("select MAX(copy_id) from copies where mediaformat = 2 ").to_i
  end

  def self.unreturned_and_billable_at(enddate)
    unreturned_and_billable_at_internal(enddate, "DISTINCT c.*")
  end

  def self.unreturned_and_billable_at_pricesum(enddate)
    ret = unreturned_and_billable_at_internal(enddate, "sum(purchase_price + #{REPLACEMENT_PRICE_DELTA}) as 'total_price'" )
    ret[0].total_price.to_f
  end
    
  def self.unreturned_and_billable_at_internal(enddate, sql_sub)
    # First, create a table that gives the most recent death type of each copy up to and including the final day of the period.
    # E.g. if    2008-01-01: born
    #            2008-02-01: scratched
    #            2008-03-01: polished
    # then for a period ending on 2008-02-15, the most recent death type is 'scratched'.

    ActiveRecord::Base.connection.execute("CREATE TEMPORARY TABLE latest_status
                                           SELECT death_logs.* 
                                           FROM death_logs, (
                                           SELECT copy_id, max(editDate) as 'editDate' 
                                           FROM death_logs 
                                           WHERE editDate <= '#{enddate.to_s}' 
                                           GROUP BY copy_id ) mostrecent 
                                           WHERE death_logs.copy_id = mostrecent.copy_id 
                                           AND death_logs.editDate = mostrecent.editDate")

    # Now join the copy table against the latest_status table.
    # Any copy that either has a most recent transition to 0 ('not dead'), or
    # has NULL (meaning it ** never ** had a transition in the death log), is 
    # defined as 'good'.
    
    ret = Copy.find_by_sql("SELECT  #{sql_sub}
                        FROM shipments sh, copies c left join latest_status ls on c.copy_id = ls.copy_id, orders co, credit_cards cc, line_items li, product t
                        WHERE li.shipment_id = sh.shipment_id
                        AND ISNULL(dateBack)
                        AND li.copy_id = c.copy_id
                        AND c.product_id = t.product_id
                        AND (ls.newDeathType = 0 OR ISNULL(ls.newDeathType))
                        AND mediaFormat = 2
                        AND ! ISNULL(lateMsg2Sent)
                        AND ( to_days(lateMsg2Sent) + 14 < to_days('#{enddate.to_s}'))
                        AND li.orderID = co.orderID
                        AND co.customer_id = cc.customer_id")

    ActiveRecord::Base.connection.execute("DROP TABLE latest_status")
    ret
  end

  def self.need_prices_for_billing
    Copy.unreturned_and_billable.map { |cc| cc.product}.select { |tt| purchase_price.nil?}
  end

  def self.make_copies_visible
    ActiveRecord::Base.connection.execute("UPDATE copies SET visibleToShipperP = 1")
  end

  def self.make_copies_unreserved
    ActiveRecord::Base.connection.execute("UPDATE copies SET tmpReserve = 0");
  end

  def self.find_shippable_copy(product_id)
    Copy.find(:first, :conditions =>"product_id = #{product_id} AND status = 1 AND visibleToShipperP = 1 AND inStock = 1 AND mediaformat = 2 AND tmpReserve = 0")
  end
  
  def self.find_shippable_copy_a(product_ids)
    Copy.find(:all, :conditions =>"product_id in (#{product_ids.join(',')}) AND status = 1 AND visibleToShipperP = 1 AND inStock = 1 AND mediaformat = 2 AND tmpReserve = 0",
              :group => "product_id")
  end
  


  # get a list of copies that are bad in a way that we want to catch them in the returns process
  def self.good_copies
    Copy.find(:all).select { |copy| DeathLog::AUTOMATICALLY_MARK_AS_HEALED.include?(copy.deathType) }
  end
  
  
end

require 'date'
class Date
  def copies_returned_this_date
    LineItem.find_all_by_dateBack(Date.today.to_s).map(&:copy)
  end
end

class Inventory < ActiveRecord::Base
  attr_protected # <-- blank means total access

  self.primary_key = 'inventoryID'

  WINDOW_DAYS_RECENT = 14
  ALLOWED_TIME_OUT = 25

  def self.recent?(copy_id)
    inventory = Inventory.find(:all, :conditions => "startID <= #{copy_id} AND endID >= #{copy_id} AND (TO_DAYS(now()) - #{WINDOW_DAYS_RECENT}) < TO_DAYS(inventoryDate)")
    inventory.any?
  end

  def self.suggest_start
    # find the first DVD in our inventory
    min_id = Copy.min_id

    # we store DVDs in rows of 200 in drawers.  Find the last full drawer.
    max_id = Copy.max_id
    max_id = max_id - (max_id % 200 + 1)

    # find out when each copy was last inventoried
    last_inv = Hash.new(Date.parse("2000-01-01"))
    Inventory.find(:all).each do |inv| 
      inv.startID.upto(inv.endID) do |copy_id|
        last_inv[copy_id] = inv.inventoryDate if inv.inventoryDate >= last_inv[copy_id]
      end 
    end


    if last_inv.empty?
      start_id = Copy.find(:first).id
    else
      saddest_copy_id = last_inv.min_by { |copy_id, date|  date }.min_by { |copy_id, date|  copy_id }
      oldest_date = last_inv[saddest_copy_id]
      start_id = last_inv.select { |copy_id, date| date == oldest_date }.map { |copy_id, date| copy_id}.min
      
      start_id = nil if ((Date.today - last_inv[start_id]) < ALLOWED_TIME_OUT)
    end
    start_id

  end

  def self.freshness_percent

      # Get highest copy_id
      maxCopyID = Inventory.find_by_sql("SELECT MAX(copy_id) AS maxCopyID FROM copies")[0].maxCopyID.to_i
      
      # Get all inventories in last 14 days (this value should be same
      # as used in TvrSql::inventoryRecentP()) and add up the number
      # of elements in the total range covered
      
      boundary = Date.today - 25 
      res = Inventory.find(:all, :conditions=> "inventoryDate >= '#{boundary.to_s}'")
      
      range = []
      
      res.each do |r|
        range |= (r.startID..r.endID).to_array
      end

    (range.size.to_f * 100.0) / (maxCopyID - 1999).to_f

  end

end

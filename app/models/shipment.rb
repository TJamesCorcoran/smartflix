class Shipment < ActiveRecord::Base
  self.primary_key ="shipment_id"

  attr_protected # <-- blank means total access

  has_many :line_items
  has_many :products, :through => :line_items
  has_many :copies, :through => :line_items
  has_many :orders, :through => :line_items, :uniq => true

  def customer()    orders.first.customer end

  # Return date the post office probably got the video; if the shipment
  # time is at or before 11AM, then the shipment day, else the business
  # day after (no shipping on weekends)

  def posted_on
    ship_boundary = Time.local(self.dateOut.year, self.dateOut.month, self.dateOut.day, 18)
    ship_date = (self.time_out <= ship_boundary) ? self.dateOut : self.dateOut + 1
    case ship_date.wday
    when 6 then return ship_date + 2
    when 7, 0 then return ship_date + 1
    else return ship_date end
  end

  def ship_time_range
    customer = self.line_items.first.order.customer
    if (customer.shipping_address.country.name == 'USA' || customer.shipping_address.country.name == 'United States')
      (3..8)
    else
      (5..15)
    end
  end

  def early_arrival
    posted_on + ship_time_range.min
  end

  def late_arrival
    posted_on + ship_time_range.max
  end

  # if we need to ship X dvds, and we don't even know if they're all in stock, or not
  # what cost should we assume for the eventual shipment ?
  def Shipment.default_cost(size)
    size * 4
  end

  def one_direction_postage
    return 0.0 if  (! physical) || line_items.empty?
    weight_oz = DvdWeight.find_weight(boxP, line_items.size).andand.weight_oz
    raise "illegal shipment" if weight_oz.nil?
    postage_cents = UspsPostageChart.search("parcel", "first", weight_oz, nil, Date.today).andand.price_cents
    raise "illegal shipment" if postage_cents.nil?
    postage_cents / 100.0
  end
  
  def cost
    size = line_items.size

    # XYZFIX P3: could take into account different depreciation rates with envelopes...
    # XYZFIX P3: should really apply a depreciation RATE to the prices of individual dvds rented
    #  ... or better yet, look at ACTUAL BREAKAGE / LOSSAGE !!!!!!!
    #
    cost  = size * 1.0 # depreciation
    cost += size * 0.5 # labor
    cost += 0.04 # outgoing_label

    if boxP
      cost +=
        0.10 + # 3-part return label
        0.01   # tape to seal box
        0.13   # postage machine rental and ink

      # boxes, based on number of DVDs
      shipping_containers = { 1 => 0.46, 2 => 0.46, 3 => 0.46, 4 => 0.46 }
      shipping_containers.default = 0.60
      cost += shipping_containers[size]
    else
      cost += 0.05 # envelope
    end
    cost + (2 * one_direction_postage)  # add postage
  end
  
  def bus_reply_cost
    one_direction_postage
  end
  
  def permit_imprint_cost
    boxP ? 0.00 : one_direction_postage 
  end

  def usps_weight_oz
    DvdWeight.find_weight(boxP, line_items.size).andand.weight_oz
  end
  
  def usps_type
     boxP ? :parcel : :flat
  end

  def mark_as_lost
    copies.each { |copy| copy.mark_dead(DeathLog::DEATH_LOST_IN_TRANSIT, "via tvr-master") }
  end
  
end

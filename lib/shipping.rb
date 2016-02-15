require 'digest/md5'

Copy
class Copy
  attr_accessor :colored
end

GiftCert
class GiftCert
  attr_accessor :colored
end

# How this code works
# -------------------
#
# 1) create_list()  -> creates a hash, mapping customers to 1+ shipments (each a list of copies)
#     ...calls create_customer_coli_pairs() to do the heavy lifting
# 2) save_to_db()
#

# In more detail
# --------------
# 1) create_list() 
#      * create_customer_coli_pairs            // make a hash of LIs to copies that fulfill them
#          * LineItem.find_open_grouped_by_order // find LIs in open orders
#          * for each order:
#             * find_copies_for_lis(ligroup)        // match copies to LIs
#             * prune_preconded_items               // peel off LIs / copies that are preconded
#             * prune_for_throttling                // peel off LIs / copies that exceed thresholds
#      * breakUpShipments
# 2) save_to_db()
#

class Shipping

  @@verbose = true

  @@logger = method(:puts)   
  cattr_accessor :logger

  @@precondition_cache = {}
  def self.lookup_precondition(copy)
    product = copy.product
    return @@precondition_cache[product] if @@precondition_cache.has_key?(product)
    return @@precondition_cache[product] = product.precond
  end

  def self.prune_preconded_items(customer, pairs)

    copy_workset = pairs.inject({}) { |hash, pair| hash[pair[:copy]] = true ; hash }
    product_workset = copy_workset.keys.inject({}) { |hash, copy| hash[copy.product] = true ; hash }

    # Repeatedly loop over copies, removing anything that doesn't have a
    # valid precondition either in the copy set itself or in the set of
    # things the customer has rented or is explicitly not interested in

    progress = true
    while progress
      progress = false
      copy_workset.keys.each do |copy|
        next if !lookup_precondition(copy)
        next if product_workset[lookup_precondition(copy)]
        next if !customer.ever_ordered_product?(lookup_precondition(copy))
        next if customer.ever_shipped_product?(lookup_precondition(copy))
        copy_workset.delete(copy)
        product_workset.delete(copy.product)
        progress = true
      end
    end

    pairs.select { |pair| copy_workset[pair[:copy]] }

  end

  # Partial ordering - shift things wo preconds to the left.
  # NOTE: we could be smarter here
  def self.partial_sort(li_copy_pairs)
    # TJIXFIX P2: make this work with the test_create_list() in test/unit/shipping_test.rb
#    li_copy_pairs = li_copy_pairs.sort{|apair,bpair| a = apair[:copy] ; b = bpair[:copy] ; (a.precond.nil?) ? -1 : ((b.precond.nil?) ? 1 : a.precond.product_id <=> b.precond.product_id )}
    li_copy_pairs
  end

  def self.sort_by_queue_order(li_co_pairs)
    li_co_pairs.sort_by { |hh| hh[:li].queue_position || 99999 }
  end

  # Prune for throttling has two parts:
  #   1) regular orders    - obey the rule for shipp-rate (max of 2X in field)
  #   2) university orders - obey the univ rules (complicated: monthly payment, num in field, etc.)
  #
  # To add a complication: a customer can be subbed to, say, two
  # univs, AND regular smartflix.
  #
  # To add another complication: we may have already allocated a few copies for a customer
  # for an older order.  Those allocated copies count against his allotment, at least in some cases
  # (e.g. the nil university ( == smartflix ) case.
  # ... in this case, we need to tell the lower level code that X items are already allocated.
  # So: search through the allocated DVDs for those that match each univ and pass it in.
  # 
  def self.prune_for_throttling(customer, li_copy_pairs, already_allocated_li_co_pairs)
    # hard throttling
    return [] if (customer.throttleP)
    
    shippable_pairs = []
    
    # group the orders by univ (we might have 3 orders for SMARTFLIX and 2 for WOODTURNING)
    #
    # The original code is just
    #    grp_by_univ = li_copy_pairs.group_by{|pair| pair[:li].order.university }
    #
    # The new code is trickier, to get a speedup
    #
    order_id_to_univ = li_copy_pairs.map { |pair| pair[:li].order_id }.uniq.map { |order_id| [order_id, Order[order_id].university]}.to_hash
    grp_by_univ = li_copy_pairs.group_by{|pair| order_id_to_univ[pair[:li].order_id] }

    # iterate by univ
    grp_by_univ.keys.each do |univ|

      pairs = partial_sort(grp_by_univ[univ])

      raise univ.inspect if pairs.nil?
      
      # some items are freebies - they're replacements for other
      # items, and get to ignore the shipping limit for them 
      
      freebies = pairs.select { |pair| pair[:li].ignore_for_univ_limits }

      pairs = pairs - freebies
      
      # find out how many copies are already about to be shipped for other orders from this
      # same university
      relevant_allocated_pairs = already_allocated_li_co_pairs.select { |pair|
        pair[:li].order.university_id == univ && ! pair[:li].ignore_for_univ_limits
      }
      
      limit = customer.shippable_count_for_univ(univ, relevant_allocated_pairs.size)

      name = ""
      name = University.find(univ).name if univ

      # logger.call "XXX pairs = #{pairs.inspect} // cust = #{customer.inspect}"

      shippable_pairs += freebies
      shippable_pairs += pairs[0, limit] || []
      
    end
    
    shippable_pairs
    
  end

  # break up shipments so that we don't put too many eggs in one (uninsured) basket
  VALUE_CUTOFF = 8
  def self.breakUpShipments(coli_pairs)
    running_total = 0
    shipments = []
    one_ship = []
    coli_pairs.each do |coli_pair|
      one_ship << coli_pair
      running_total += coli_pair[:copy].value
      if running_total >= VALUE_CUTOFF
        shipments << one_ship
        one_ship = []
        running_total = 0
      end
    end
    shipments << one_ship if ! one_ship.empty?
    shipments
  end

  def self.save_to_db(customer_to_shipments)
    PotentialShipment.destroy_all
    PotentialItem.destroy_all
    
    customer_to_shipments.each_pair do |cust, shipments|
      shipments.each do |items|
        copy_colis     = items.select { |item| item[:copy].is_a?(Copy) }
        giftcert_colis = items.select { |item| item[:copy].is_a?(GiftCert) }

        ps = PotentialShipment.new
        ps.customer = cust
        copy_colis.each    { |coli_pair| 
          copy = coli_pair[:copy]
          li = coli_pair[:li]
          ps.potential_items << PotentialCopy.new(:copy => copy, :line_item => li) 
        }
        giftcert_colis.each { |coli_pair|
          gc = coli_pair[:copy]
          li = coli_pair[:li]
          ps.potential_items << PotentialGiftCert.new(:gift_cert => gc, :line_item => li)
        }

        # * use md5
        #   - outputs 22 useful bytes instead of just 8
        #   - outputs into the characterspace [a–zA–Z0–9./]
        #   - we fold lowercase -> uppercase to get [A–Z0–9./]
        #   - code39 requires inputs in the characterspace [A–Z0–9.-$/+%SPACE]
        #     = 28 values
        #     = 4.6 bits/char 
        #       we take 10 characters of material (to fit on a physical barcode)
        #     = 46 bits
        #     = 2^46 possible values
        #     = hash collisions unlikely
        # * prefix barcode text proper with "X" to move it to a namespace distinct from
        #     copy_id barcodes, etc.  
        copies = copy_colis.map { |coli| coli[:copy] }
        giftcert_lis = giftcert_colis.map { |coli| coli[:li] }
        ps.barcode = "X" + Digest::MD5.hexdigest(cust.shipping_address.to_s + copies.map(&:copy_id).join("|") + "|" + giftcert_lis.map(&:product_id).join("|")).upcase[0,10]
        ps.save
        
      end
    end
  end

  # given some line_items, return an array of li/co pairs
  #
  # Note that the cod is a bit tricky, but this gives us a speedup from 5 seconds to
  def self.find_copies_for_lis(lis)
    # OLD - takes 5 seconds
    #       lis.each do |li|
    #         copy = Copy.find_shippable_copy(li.product_id)
    #         li_co_pairs << {:li => li, :copy => copy} if ! copy.nil?
    #         li_co_pairs << {:li => li, :copy => li.product} if copy.nil? && li.product.is_a?(GiftCert)
    #       end
    #       puts "QQQQQQQQ #{li_co_pairs.inspect}"

    li_co_pairs = []

    # build a lookup table for efficiency; now we can find lis by product_id
    productid_to_li = lis.map { |li| [ li.product_id, li ]}.to_hash
    
    # get a bunch of copies, all in one fell swoop ^H^H^H query
    copies = Copy.find_shippable_copy_a(lis.map(&:product_id))

    # build the li_co_pairs:
    #     [ {:li => li, :copy => copy}, {:li => li, :copy => copy} ]
    li_co_pairs = copies.map { |copy| { :li => productid_to_li[copy.product_id], :copy => copy} }

    lis.select { |li| li.isa_GiftCert? }.each do |li|
      li_co_pairs << { :li => li, :copy => li.product }
    end

    li_co_pairs
  end

  # input:
  #    [ OPTIONAL ] customer - * limits the query to one customer.
  #                            * not perfect: may give the customer copies that an earlier
  #                                order for some other customer would actually get
  #                            * ONLY TO BE USED IN DEVELOPMENT !!!
  #
  # return:
  #   { customer -> [ {:co => copy, :li => li}, {:co => copy, :li => li} ],
  #     customer -> [ {:co => **GIFCERT**, :li => li}] ],
  #   }
  def self.create_customer_coli_pairs(customer = nil)
    
    logger.call "* about to get open LIs - this takes ~ 90 s"
    lis_grouped_by_order = LineItem.find_open_grouped_by_order

    lis_grouped_by_order.reject! {  |order,lis| 
      if order.customer.nil? 
        puts "XXX no customer for order ##{order.id}"
        true
      end
    }

    if customer
      customer = Customer[customer] if customer.is_a?(Fixnum)
      puts "**** running in debug mode - selecting only #{customer.id} // #{customer.email}" if @@verbose
      lis_grouped_by_order = lis_grouped_by_order.select { |order, lis| order.customer_id == customer.id }.to_h
    end

    Copy.make_copies_unreserved

    # We first group by order (** NOT ** by customer ... because we
    # don't want to have a customer with one open LI from 6 months ago
    # getting priority on things he ordered yesterday over someone who
    # ordered the same item 4 months ago).
    #
    # We then go through these orders in chronological order, and build up
    # shipments in the customer_to_pairs hash.
    customer_to_pairs = Hash.new { |hash, key| hash[key] = Array.new }

    start = Time.now 
    ii = 0             

    # some orders don't have order dates - WT* ?
    lis_grouped_by_order.keys.sort_by { |order| order.orderDate || (Date.today << 100) }.each do |order|

      ii += 1
      before = start = Time.now
      # @@logger.call "#{ii} // #{order.id} // #{order.university.andand.name}"

      # setup
      ligroup = lis_grouped_by_order[order]
      customer = order.customer
      
      # find copies to fulfill LIs
      li_co_pairs = self.find_copies_for_lis(ligroup)

      # logger.call "AAA -    find shippable #{Time.now - before}"

      # prune as needed
      # 
      # IMPORTANT NOTE: it would be easier for lots of reasons to
      # prune before copy assignment, but the best pruning is pruning
      # something that's not in stock anyway (no customer impact), so
      # we need to do assingment first, THEN prune.
      #
      before = Time.now

      li_co_pairs = prune_preconded_items(customer, li_co_pairs)

      next if  li_co_pairs.nil?
      next if  li_co_pairs.empty?
      next if li_co_pairs.first[:li].order.customer == Customer.find_by_customer_id(257064)

      # sort the line items by university queue order, if any
      #
      li_co_pairs = sort_by_queue_order(li_co_pairs)

      # why do we pass in customer_to_pairs?  So that the throttling code can see what
      # we've already decided to ship to this customer (that quantity plays into throttling!) 

      before = Time.now
      li_co_pairs = prune_for_throttling(customer, li_co_pairs, customer_to_pairs[customer] )


      # reserve the copies we intend to send
      li_co_pairs.map{|pair| pair[:copy]}.each { |copy| copy.reserve}
      customer_to_pairs[customer] += li_co_pairs

    end
    logger.call "TOTAL TIME : #{Time.now - start}" ; before = Time.now # 
    customer_to_pairs
  end

  # returns a hash:
  #   { customer -> [ [ [:li => li1, :co => copy1],   [:li => li2, :co => copy2]],
  #                     [:li => li3, :co => copy3]],
  #     customer -> [ [ [:li => li4, :co => copy4],   [:li => li5, :co => copy5]] ]
  #   }
  def self.create_list
    coli_pairs = create_customer_coli_pairs
    # we've got
    #    { cust1 => [  [:li => li1, :co => copy1],   [:li => li2, :co => copy2] ... ], 
    #      cust2 => [  [:li => li20, :co => copy21], [:li => li21, :co => copy21] ... ] ...}
    # convert that to just copies, and then break up by shipment size:
    #    { cust1 => [  [copy1, copy2], [ copy3 ] ],
    #      cust2 => [  [copy1] ] ...  }
    #
    ret = {}
    coli_pairs.keys.each do |customer|
      ret[customer] = breakUpShipments(coli_pairs[customer])
    end
    ret
  end

  # given a potential shipment
  #   1) create an actual shipment
  #   2) find the lineitems that go in it
  #   3) connect them with the actual shipment
  #   4) mark the copies out of stock
  def self.make_potential_shipment_real(potential_shipment)

    # We're touching Shipments, LIs, potential_shipments, copies, and
    # potential_items - better do a transaction, bc a failure part way
    # through would be a mess!
    Shipment.transaction do
      
      actual_ship = Shipment.create!(:dateOut => Date.today, :time_out => Time.now, :boxP => (potential_shipment.boxP  ? 1: 0), :physical=>true)
      
      # this is a bit tricky: the potential items can be either copies
      # of gift certs
      #
      potential_shipment.potential_items.each do |pot_item|
        li = pot_item.line_item
        raise "no li for product_id #{pot_item.copy.product_id}" if li.nil?
        li.update_attributes(:shipment => actual_ship, :copy => pot_item.copy)
        # if this is a copy, remove it from stock
        pot_item.copy.andand.remove_from_stock
      end
      potential_shipment.destroy
    end
  end

  def self.toplevel_recalc
    @@logger.call "* begin at #{Time.now}"
    
    # XYZFIX P2 - can we just yank all of the "visible" stuff out?
    Copy.make_copies_visible
    
    # XYZFIX P2
    # ugly hack - figure out why there are LIs w order_id == 0 instead
    LineItem.find(:all, :conditions => "order_id = 0").each { |li| li.cancel(true) }
    
    @new_shipments = Shipping.create_list
    
    PotentialShipment.destroy_all
    PotentialItem.destroy_all
    Shipping.save_to_db(@new_shipments)
    
  end
  
  #----------------------------------------
  # unshippable functions - we use these to send out mail to folks telling them "order is unshippable"
  #----------------------------------------
  
  def self.orders_being_partially_shipped_today
    PotentialItem.find(:all).map(&:line_item).map(&:order).uniq
  end

  # find unshippable orders
  # definition: any order that
  #    - has not had a single item shipped
  #    - is not queued up to ship today 
  def self.unshippable
    raise("shipping not calculated; subtraction will fail") unless PotentialItem.count > 0
    # takes about 5 minutes (XYZ 1 Apr 2010)
    unshipped_orders = LineItem.find_open_grouped_by_order.keys
    # takes  about 0.5 minutes ; total = 5.5 min
    unshipped_orders - orders_being_partially_shipped_today
  end

  
  def self.unshippable_unpaid()    unshippable.select{ |order| order.paid?.not }  end
  def self.unshippable_oos()       unshippable.select{ |order| order.paid? }      end

  #----------
  # funcs for job_runner task that sends out emails
  # 

  # prune away orders that are unshippable, but which we don't want to report on
  #
  # Q: Why are we pruning out orders that arrived today?
  #
  # A: Bc the core of the algorithm is that something is unshippable
  # if it should be shippable, but it's not scheduled to ship right
  # now. ... and there's a loophole that lets perfectly valid
  # shippable things raise false alarms.
  # 
  # E.g. timeline:
  #    * order 1
  #    * order 2
  #    * order 3
  #    -------------------------- midnight
  #    * order 4
  #    * calculate shipping
  #    * order 5
  #    * out-of-stock
  # out-of-stock can give valid answers for 1,2,3, but can not say
  # anything meaninful about order 5.
  #
  # We work around this by pruning out orders from the same day.  Note
  # that we lose the ability to report on order 4, until one more day
  # passes.  Oh well.  We don't mind that.
  #
  def self.prune_unshippables(orders)
    ret = orders.reject { |o| o.unshippedMsgSentP || 
                        o.university || 
                        o.created_at < Date.parse("2010-03-01") ||
                        o.orderDate == Date.today   }
  end

  def self.unshippable_unpaid_mention() prune_unshippables(unshippable_unpaid)  end
  def self.unshippable_oos_mention()    prune_unshippables(unshippable_oos)  end

end

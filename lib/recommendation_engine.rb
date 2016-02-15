# Class that provides customer recommendations based on what a customer has
# rented as compared to what everyone else has rented. Can also simply
# generate recommendations based on a single title

class RecommendationEngine
  
  @@logger = method(:puts)   
  cattr_accessor :logger
  
  
  def initialize()
    
    @master_db = LineItem.connection
    
    # Build hash of arrays of product_ids, indexed by customer_id, and hash of
    # weighted title IDs, weight based on how long ago something was rented
    
    @titles_by_customer = Hash.new
    @weighted_titles_by_customer = Hash.new
    
    # filter out garbage data : " customer_id !=0   "
    
    # # XYZFIX P3 - note that we're only using data from the last
    # 365 days.  that's sort of bogus - we'd be happy to use data from
    # all of history, but only INSERT data (which is expensive) for
    # customers who've visited more recently than that.
    # 
    
    res = @master_db.select_all("SELECT orders.customer_id, line_items.product_id,
                                    DATEDIFF(CURDATE(), orderDate) AS daysAgo
                               FROM orders, line_items
                          LEFT JOIN product_set_memberships ON line_items.product_id=product_set_memberships.product_id
                              WHERE orders.order_id=line_items.order_id
                                AND (DATEDIFF(CURDATE(), orderDate) < 365)
                                AND customer_id !=0  
                                AND (product_set_memberships.ordinal=1 OR ISNULL(product_set_memberships.ordinal));")
    
    res.each() do |row|
      
      @titles_by_customer[row["customer_id"]] ||= Array.new
      @titles_by_customer[row["customer_id"]] << row["product_id"]
      
      # Given a number of days ago, calc a weighting multiplier ranging from 1.0 to 0.5
      time_weight = [1.0 - row["daysAgo"].to_f / 730.0, 0.5].max
      
      @weighted_titles_by_customer[row["customer_id"]] ||= Hash.new
      @weighted_titles_by_customer[row["customer_id"]][row["product_id"]] = time_weight
      
    end
    
    # Now build graph between titles with weighted edges based on person who
    # rented X also rented Y, Z, etc. Ignore time based weightings here
    
    @graph = Hash.new
    
    @titles_by_customer.values.each do |title_ids|
      title_ids.each do |title_id1|
        @graph[title_id1] ||= Hash.new(0)
        title_ids.each do |title_id2|
          if (title_id1 != title_id2)
            @graph[title_id1][title_id2] += 1
          end
        end
      end
    end
    
    # Build a quick lookup for what copies are currently in stock
    
    @title_stock_count = Hash.new(0)
    
    res = @master_db.select_all("SELECT product_id, COUNT(IF(inStock=1,1,NULL)) AS numInStock
                               FROM copies
                              WHERE mediaformat=2
                                AND status=1
                           GROUP BY product_id;")
    
    res.each() { |row| @title_stock_count[row["product_id"]] = row["numInStock"].to_i }
    
  end
  
  # Given a customer ID and a number of recommendations, return that many
  # appropriate recommendations for that customer; optionally, only list
  # in stock titles, or titles not in a list of title IDs to reject
  
  def get_cust_recs(cust_id, num_recs, instock = true, reject_list = [])
    
    cust_id = cust_id.to_s
    
    rented_ids = @titles_by_customer[cust_id]
    
    return([]) if rented_ids.nil?
    
    # For each user, find the titles they would be most interested in
    
    rec_ids = Hash.new(0)
    
    # Predefine some variables for speed
    rented_id = rec_id = weight = time_weight = nil
    
    rented_ids.each do |rented_id|
      
      # Skip if no recommendations based on a given title
      next if (@graph[rented_id].nil?)
      
      # For each title they rented, weighed by how long ago they rented it,
      # get all the titles that are in the graph related to that title, and
      # note their weights
      
      time_weight = @weighted_titles_by_customer[cust_id][rented_id]
      
      @graph[rented_id].each do |rec_id, weight|
        rec_ids[rec_id] += (weight * time_weight)
      end
      
    end
    
    # Get the list of all titles, sorted by weight (we sort based on the
    # second element, weight, then just pull out the first element, product_id)
    
    rec_list = rec_ids.sort { |a, b| b[1] <=> a[1] }.collect { |v| v[0] }
    
    # Prune titles they've already rented
    rec_list -= rented_ids
    
    # If the caller desires, prune all the titles that are not currently in stock
    if (instock)
      rec_list = reject_out_of_stock(rec_list)
    end
    
    # Prune out any titles in the reject list
    if (reject_list.size > 0)
      rec_list = rec_list.reject { |id| reject_list.include?(id.to_s) || reject_list.include?(id.to_i) }
    end
    
    # Return the first num_recs recs
    return(rec_list[0,num_recs])
    
  end
  
  # Iterate through all customers, yielding the customer ID and an array of
  # recommendations (each with the amount specified)
  
  def num_titles_by_customer()      @titles_by_customer.keys.size end

  #----------
  #   iterators
  #----------

  
  def iterator(input_hash, num_recs, block, func )

    skip = 0
    
    input_hash.keys.each do |cust_id|
      
      cust  = Customer.find_by_customer_id(cust_id)
      unless cust && cust.last_order && cust.last_order.created_at > (Date.today << 12)
        skip += 1
        @@logger.call "skipping for oldness - #{skip} total" if skip % 20 == 0
        next
      end 
      
      # we only call the function to get the results for a customer after we've
      # decided that the customer is worthy of getting results
      results = func.call(cust_id , num_recs)
      
      block.call( cust_id, results )
    end
    
  end

  # These are the two custom interators that we use.
  # 
  # They share a bunch of similar code, so we've done a bit of tricky refactoring
  # to put the common code (ignoring stale customers) in the 'iterator()' method
  #
  def each_cust_recs(num_recs, instock, all_customers, &block )
    func = method(:get_cust_recs) # get_cust_recs(cust_id, num_recs, instock)
    iterator(@titles_by_customer, num_recs, block, func  )
  end

  def each_cust_category_recs(num_recs, &block )
    func = method(:get_cust_category_recs) # get_cust_category_recs(cust_id, num_recs)
    iterator(@titles_by_customer,  num_recs, block, func )
  end
  
  # Given a customer ID and a number of category recommendations
  # desired, return that many recommended categories for the customer
  
  def get_cust_category_recs(cust_id, num_recs)
    
    # Not-super-clever-but-probably-ok-even-though-it's-slow: see what
    # titles we'd recommend to this customer, and see what categories
    # those are in (we could cache/memoize to make this faster), then
    # combine this with the categories they've actually rented in.
    
    rec_ids = get_cust_recs(cust_id, 100)
    return [] if rec_ids.size == 0
    
    cat_ids = []
    
    # First, categories they've rented
    res = @master_db.select_all("SELECT category_id FROM categories_products WHERE product_id IN (#{@titles_by_customer[cust_id.to_s].join(',')})")
    res.each { |row| cat_ids << row["category_id"] }
    
    # Then, categories from titles we'd recommend
    res = @master_db.select_all("SELECT category_id FROM categories_products WHERE product_id IN (#{rec_ids.join(',')})")
    res.each { |row| cat_ids << row["category_id"] }
    
    # Sort them by a combination of how early in the list they show up
    # and how often they show up
    
    weighted_cats = Hash.new(0)
    cat_ids[0,100].each_with_index { |cat_id, i| weighted_cats[cat_id] += ((125 - i) / 25.0) }
    
    return weighted_cats.sort { |a, b| b[1] <=> a[1] }.collect { |v| v[0] }[0,num_recs]
    
  end
  
  # Given a title, get the appropriate number of recommendations for related
  # titles
  
  def get_title_recs(title_id, num_recs, instock = true)
    
    title_id = title_id.to_s
    
    return [] if (@graph[title_id].nil?)
    
    rec_ids = Hash.new(0)
    
    @graph[title_id].each { |rec_id, weight| rec_ids[rec_id] += weight }
    
    # Get the list of all titles, sorted by weight (we sort based on the
    # second element, weight, then just pull out the first element, product_id)
    
    rec_list = rec_ids.sort { |a, b| b[1] <=> a[1] }.collect { |v| v[0] }
    
    # If the caller desires, prune all the titles that are not currently in stock
    if (instock)
      rec_list = reject_out_of_stock(rec_list)
    end
    
    # Return the first num_recs recs
    return(rec_list[0,num_recs])
    
  end
  
  private
  
  def reject_out_of_stock(titles)
    
    selected = titles.select { |id| @title_stock_count[id] > 0 }
    
    # Some output showing if we're doing poorly
    
    # XXXFIX P4: if in debug mode, log this stuff
    if (false)
      samples = [10, titles.size].min
      instock = (titles[0,samples] & selected).size
      if (samples >= 5 && instock <= samples / 3)
        @@logger.debug "Only #{instock} out of the top #{samples} titles we'd like to recommend are in stock"
      end
      if (titles.size >= 10 && selected.size < 8)
        @@logger.debug "Only #{selected.size} out of the #{titles.size} titles we'd like to recommend are in stock"
      end
    end
    
    return selected
    
  end
  
  public
  
  #--------------------
  # interface for job runner
  #--------------------

  #----------
  #   products_recommendations
  #----------
  def toplevel_do_products_recommendations
    
    db = LineItem.connection
    
    db.execute("delete from product_recommendations")
    
    products = Product.find(:all)
    
    inserts = []
    i = 0
    
    @@logger.call "* products_recommendations: prep"
    products.each do |product|
      i += 1
      @@logger.call " ... #{i} / #{ products.size } done"        if i % 250 == 0
      
      next if (product.product_set_membership && product.product_set_membership.ordinal != 1)
      recs = get_title_recs(product.id, 7, false)
      recs.each_with_index { |rec_id, index| inserts << "(#{product.id}, #{rec_id}, #{index})" }
      
    end
    
    @@logger.call "* products_recommendations: insert"
    i = 0
    inserts.in_groups_of(100, false) do |insert_group|
      i += 100
      @@logger.call " ... #{i} / #{ inserts.size } done"        if i % 10000 == 0
      
      db.execute("INSERT INTO product_recommendations (product_id, recommended_product_id, ordinal) VALUES #{insert_group.join(',')}")
    end
    
  end

  #----------
  #   customer_products_recommendations
  #----------
  def toplevel_do_customer_products
    @@logger.call "* customer_products_recommendations: prep"
    
    db = LineItem.connection
    
    deletes = []
    inserts = []
    
    # there are about 40,000 customers who will get recos in a full run
    #
    limit = nil
    limit = 400 if Rails.env == 'development'
    mod_reporting = 100
    
    @@logger.call "* customer_products_recommendations: here"
    ii = 0
    num = Customer.count
    before = Time.now
    each_cust_recs(10, true, false) do |customer_id, product_ids|
      ii += 1
      @@logger.call " ... #{ii.commify} of #{ num.commify } done ( #{(ii/num).percent}  ) - #{(Time.now - before)/60} minutes"        if ii % mod_reporting == 0
      
      deletes << "#{customer_id}"
      
      product_ids.each_with_index do |product_id, index|
        inserts << "(#{customer_id}, #{product_id}, #{index})"
      end
      
      break if limit && ii > limit
    end
    
    
    #-----
    # delete
    @@logger.call "* customer_products_recommendations: delete"
    ii = 0
    deletes.in_groups_of(100, false) do |delete_group|
      ii += 100
      @@logger.call " ... #{ii.commify} deletes done"
      db.execute("DELETE FROM customer_product_recommendations where customer_id in (#{delete_group.join(',')})")
    end
    
    
    #-----
    # inserts
    @@logger.call "* customer_products_recommendations: insert"
    ii = 0
    insert_num = inserts.size
    inserts.in_groups_of(100, false) do |insert_group|
      ii += 100
      @@logger.call " ... #{ii.commify} of #{ insert_num.commify } done ( #{(ii/insert_num).percent}  )"        if ii % mod_reporting == 0
      
      db.execute("INSERT INTO customer_product_recommendations
                              (customer_id, product_id, ordinal)
                       VALUES #{insert_group.join(',')}")
    end
    
    
  end
  
  #----------
  #   customer_category_recommendations
  #----------
  def toplevel_do_customer_cats

    @@logger.call "* customer_category_recommendations: prep"

    db = LineItem.connection
    
    db.execute("delete from customer_category_recommendations")
    
    inserts = []
    ii = 0
    limit = nil
    limit = 400 if Rails.env == 'development'
    mod_reporting = 100
    each_cust_category_recs(10) do |customer_id, category_ids|
      ii += 1
      @@logger.call " ... #{ii.commify} done"        if ii % mod_reporting == 0
      category_ids.each_with_index do |category_id, i|
        inserts << "(#{customer_id}, #{category_id}, #{i})"
      end
      break if limit && ii > limit
    end
    
    ii = 0
    insert_num = inserts.size
    @@logger.call "* customer_category_recommendations: insert"
    inserts.in_groups_of(100, false) do |insert_group|
      ii += 1
      @@logger.call " ... #{ii.commify} of #{ insert_num.commify } done ( #{(ii/insert_num).percent}  )"        if ii % mod_reporting == 0
      
      db.execute("INSERT INTO customer_category_recommendations
                              (customer_id, category_id, ordinal)
                       VALUES #{insert_group.join(',')}")
    end      
    
  end
  
end

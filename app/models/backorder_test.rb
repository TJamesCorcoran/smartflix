module BackorderTest
  
  # constants and logic having to do with backorder status of products.
  
  BACKORDER_WARNING_THRESHOLD = 30 # the number of days wait, at which
                                   # we choose to warn customers and
                                   # ask to confirm before placing
                                   # items in the cart.
  
  # a predicate on products, sets and bundles which tests for long backorder times
  def backordered?(threshold = BACKORDER_WARNING_THRESHOLD)
    if self.respond_to?(:products) # if this is mixed in to a group item (set, bundle) use products method
      products.inject(0){|acc, x| acc+((x.days_backorder > threshold) ? 1 : 0)} >= products.size/2
    else # assume we're mixed into a "Product" object, use self.days_backorder:
      days_backorder > threshold
    end
  end

  # Return the number of days this item is on backorder, in text format
  def wait_text
    case self.days_backorder
    when -1 then 'unknown wait'
    when 0 then 'available now, ships immediately!'
    when 1..9 then 'short wait, ships soon'
    when 10..22 then 'moderate wait'
    when 23..34 then 'long wait'
    else 'very long wait'
    end
  end
end

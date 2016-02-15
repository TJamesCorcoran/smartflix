class CartGroup
  attr_accessor :discount_multiplier, :name
  attr_reader :items


  # New cart group object
  def initialize
    @items = []
  end

  # Add an item to a cart group
  def <<(item)
    @items << item
  end

  # Handy: Access an item in the group
  def [](index)
    @items[index]
  end

  # The size of the group
  def size
    @items.size
  end

  # The key by which the group should be sorted (we use the lowest
  # item_id in the group, which is indicative of order added to cart)
  def sort_key
    @items.collect { |item| item.cart_item_id.to_i }.min
  end

  # Does this group get the set discount? Give the discount if all
  # available items are rented (ie don't require non-displayed items)
  def set_discount?
    return false unless @items[0].product.product_set_member?
    group_products = @items.collect(&:product)
    set_products = @items[0].product.product_set.products.select { |p| p.display? }
    return (group_products.size == set_products.size && group_products.sort == set_products.sort)
  end

  # Does this group get the bundle discount?
  def bundle_discount?
    return false if @items.size == 1
    group_products = @items.collect(&:product)
    @items.first.product.product_bundles.each do |bundle|
      return true if group_products.size == bundle.products.size && group_products.sort == bundle.products.sort
    end
    return false
  end

  # Given a specific bundle, does this group match this bundle exactly?
  def matches_bundle?(bundle)
    group_products = @items.collect(&:product)
    bundle_products = bundle.products
    return (group_products.size == bundle_products.size && group_products.sort == bundle_products.sort)
  end

  def total_without_group_discount
    @items.inject(BigDecimal('0.0')) { |sum, item| sum + item.product.price - (item.discount ? item.discount : BigDecimal("0.0"))}
  end

  # What is the total price for this group (includes set or bundle discount)
  def total
    total = total_without_group_discount
    total = ApplicationHelper.round_currency(total * discount_multiplier) if (self.discount_multiplier)
    return total
  end

  # What are the set or bundle savings?
  def savings
    return self.total_without_group_discount - self.total
  end

  # Return the items in the group sorted for display order
  def sorted_items
    if (self.bundle_discount?)
      # Odd... we recurse down and use the group builder to sort within this bundle
      groups = CartGroup.groups_for_items(@items, :bundles => false)
      return groups.collect(&:sorted_items).flatten
    elsif (self.set_discount?)
      return @items.sort_by { |item| item.product.product_set_ordinal }
    else
      return @items
    end
  end

  # Iterate through the items in the group, yielding the item and the
  # price for the item; this accounts for set discounts, where the set
  # price is placed on the last item in the set and every other item has
  # a price of $0.00
  def items_with_prices

    sorted_items = self.sorted_items

    if (self.set_discount? || self.bundle_discount?)
      sorted_items[0,sorted_items.size-1].each { |item| yield(item, BigDecimal('0.0')) }
      yield(sorted_items[-1], self.total)
    else
      sorted_items.each { |item| yield(item, item.product.price) }
    end

  end

  # Take a list of items and bin them so sets and bundles are grouped
  # and ordered properly; this returns an array of CartGroup objects; it
  # can be called with a :bundles option, which can be used to turn
  # bundle bundling off (default is on)

  def CartGroup.groups_for_items(items, options = {})

    options.assert_valid_keys(:bundles,:discount)
    options[:bundles] = true if options[:bundles].nil?

    keyed_groups = Hash.new() { |h, k| h[k] = CartGroup.new }

    if (options[:bundles])

      # First see if we can build any groups that are full bundles; only
      # full bundles are accepted, partial bundles are discarded; there's
      # the added complication that a product might be part of multiple
      # bundles, but can only count towards one on checkout...

      # Step 1: set up a group for each bundle
      items.each do |item|
        next unless item.product.product_bundle_member?
        item.product.product_bundles.each { |bundle| keyed_groups[bundle] << item }
      end

      # Step 2: prune out any groups that are not complete bundles (must
      # match the specific bundle the group is filed under)
      keyed_groups.delete_if { |bundle, group| !group.matches_bundle?(bundle) }

      # Step 3: Create an inverted lookup for each item, listing all bundles it's a part of
      item_bundles = Hash.new { |h, k| h[k] = Array.new }
      keyed_groups.each { |bundle, group| group.items.each { |item| item_bundles[item] << bundle } }

      # Step 4: make sure every product is only part of one bundle; leave
      # it in the biggest bundle and remove the smaller bundles entirely
      delete_bundles = []
      item_bundles.each do |item, bundles|
        next if bundles.size == 1
        delete_bundles += bundles.sort_by { |b| b.products.size }[0,bundles.size-1]
      end
      delete_bundles.uniq.each { |delete_bundle| keyed_groups.delete(delete_bundle) }

      # Step 5: Get a list of all non-bundle items that we now still want
      # to place into groups
      items = items - keyed_groups.values.collect(&:items).flatten

    end

    # Bin all the remaining videos by set, with singletons getting their
    # own bin, indexed by product or product_set, with bins ordered by
    # cart addition order of earliest added item in set
    items.each do |item|
      bin_by = item.product.product_set_member? ? item.product.product_set : item.product
      keyed_groups[bin_by] << item
    end

    # Calculate the discount multiplier for each group, while we have the data handy, and set the group name
    keyed_groups.each do |key, group|
      if (group.set_discount? || group.bundle_discount?)
        group.discount_multiplier = options[:discount] || key.discount_multiplier
        group.name = key.name
      end
    end

    return keyed_groups.values.sort_by { |g| g.sort_key }

  end

end

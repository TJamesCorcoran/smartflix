# Define some custom exceptions that the cart can throw
class DuplicateItem < StandardError

end
class ItemNotAvailable < StandardError
end

class Cart < ActiveRecord::Base
  attr_protected # <-- blank means total access
  self.primary_key = "cart_id"

  belongs_to :customer
  has_many :cart_items, :dependent => :delete_all
  attr_accessor :global_discount

  def univ_stubs
    cart_items.map(&:product).select {|prod| prod.is_a?(UnivStub)}
  end

  def any_univ_stubs?
    univ_stubs.any?
  end

  def last_item_added_at
    items = cart_items.reject{|item| item.created_at.nil?}.sort{|a,b| a.created_at <=> b.created_at}
    return items[0].created_at unless items.empty?
    nil
  end
  
  def to_buy
    self.cart_items.reject{|i| i.saved_for_later? }
  end
  
  def wishlist
    self.cart_items.reject{|i| !i.saved_for_later? && i.product.copy_available? }
  end


  # We don't use has_many with conditions for these, because when we add
  # an item and want to look at these immediately, they will be
  # incorrect unless the data has been saved, ie we don't use
  # has_many :items_to_buy, :class_name => 'CartItem', :conditions => 'saved_for_later=0'
  # has_many :items_saved, :class_name => 'CartItem', :conditions => 'saved_for_later=1'

  # List of items in the to-buy section of the cart
  def items_to_buy
    cart_items.select { |item| !item.saved_for_later }
  end

  # List of items in the save-for-later section of the cart
  def items_saved
    cart_items.select { |item| item.saved_for_later }
  end

  # Does the cart have any items to buy?
  def empty?
    self.items_to_buy.size == 0
  end

  # Add a product to the shopping cart; this raises DuplicateItem
  # exception if the item is already in the cart or ItemNotAvailable if
  # the item has display=false
  #
  # optional arg "options" can include
  #
  #    :save_for_later - bool
  #                      true if the product is to be added to the "to-buy" portion of the cart
  #    :override_unavail - bool
  #                      true if we want to skip the "unavailable" test
  #    :override_dup    - bool
  #                      true if we want to be silent on duplicated


  def add_product(product, options = {})

    # Get the product object if an ID was passed in
    product = Product.find(product) if !product.is_a?(Product)

    # Complain about duplicates, cept for gift certs and things saved for later,

    if ((found_item=find_item_for_product(product)) &&
        !(product.is_a?(GiftCert) ||
          (found_item.saved_for_later != !options[:save_for_later].nil?)))
      return if options[:override_dup]
      raise DuplicateItem, "Product ID #{product.id} is already in the cart"
    end

    # Don't allow disabled products:
    raise ItemNotAvailable, "Product ID #{product.id} is not available" if
      (!product.display?) && ! options[:override_unavail]

    options = options.reject {|k,v| k == :override_unavail || k == :override_dup}
    # simply ignores dupes and disableds;
    cart_inserter(product, options)

  end

  # Add an entire array of products to the shopping cart; single items
  # from the array that are already in the cart are not duplicated, and
  # disabled items are simply not added; this is mostly a helper for
  # add_set and add_bundle below
  #
  # optional arg "options" can include :save_for_later, a boolean, indicating
  # if the products are to be added to the "to-buy" portion of the
  # cart (given :save_for_later => false), or the "saved for later/wishlist"
  # portion (given :save_for_later => true). --nzc Fri Feb 15 10:37:04 2008
  def add_products(products, options = {})
    products.each do |product|
      product = Product.find(product) if !product.is_a?(Product)
      cart_inserter(product, options)
    end
  end


  # Delete a product from the cart
  def delete_product(product)

    item_to_delete = find_item_for_product(product)

    if (item_to_delete)
      self.cart_items.delete(item_to_delete)
    end

  end


  # Add an entire set of products to the shopping cart
  def add_set(set, options = {})
    # Get the set object if an ID was passed in
    set = ProductSet.find(set) if !set.is_a?(ProductSet)
    self.add_products(set.products, options)
  end

  # Add an entire bundle of products to the shopping cart
  def add_bundle(bundle, options = {})
    # Get the bundle object if an ID was passed in
    bundle = ProductBundle.find(bundle) if !bundle.is_a?(ProductBundle)
    self.add_products(bundle.products, options)
  end

  # In the cart, toggle a products "saved for later" bit
  def toggle_saved_for_later(product)

    # Get the object if an ID was passed in
    product = Product.find(product) if !product.is_a?(Product)

    cart_item = find_item_for_product(product)
    if (cart_item)
      cart_item.toggle!(:saved_for_later)
    end

  end

  # Empty the cart of all to-buy items
  def empty_to_buy
    self.cart_items.delete(self.items_to_buy)
  end

  # destructively empty the cart
  def empty!
    self.cart_items.each { |ci| ci.destroy }
  end

  # Return the total price of items in the cart (not including saved items)
  def total
    CartGroup.groups_for_items(self.items_to_buy, :discount => global_discount).inject(BigDecimal('0.0')) { |sum, group| sum + group.total }
  end

  def purchase_price
    cart_items.reject{|cart_item| cart_item.saved_for_later }.map(&:product).inject(0.0){ |sum, product| sum + product.nonzero_purchase_price}
  end
  
  def savings_from_purchase
    purchase_price - total
  end

  def percent_savings_from_purchase
     "%2.0f" % (100 * (purchase_price - total) / purchase_price )
  end
  
  
  
  # Return the total price of taxable items in the cart (not including saved items)
  def taxable_total
    # We don't tax Gift Certificates (we tax the things they are used to buy)
    taxable_items = self.items_to_buy.select { |i| !i.product.is_a?(GiftCert) }
    CartGroup.groups_for_items(taxable_items, :discount => global_discount).inject(BigDecimal('0.0')) { |sum, group| sum + group.total }
  end

  # Merge one cart with another.
  #
  # This takes one option, :saved_items_only, which only merges part of
  # the cart; it defaults to false
  #
  # If an item is in both carts, but has different settings for whether
  # the item is buy now or save for later, the other cart's setting
  # takes precedent

  def merge(other, options = {})

    options.assert_valid_keys(:saved_items_only)

    merge_items = options[:saved_items_only] ? other.items_saved : other.cart_items

    merge_items.each do |other_item|
      this_item = find_item_for_product(other_item.product)
      if (this_item)
        if (this_item.saved_for_later != other_item.saved_for_later)
          this_item.update_attributes(:saved_for_later => other_item.saved_for_later)
        end
      else
        self.cart_items << other_item
      end
    end

    self.save

  end

  # Given another cart (which presumably contains items that have just
  # been bought), remove those items from this cart
  def subtract(other)

    other.items_to_buy.each do |other_item|
      this_item = find_item_for_product(other_item.product)
      if (this_item)
        self.cart_items.delete(this_item)
      end
    end

    self.save

  end

  # Calculate a unique hash representing the to-buy contents of the cart
  def cart_hash
    return Digest::MD5.hexdigest(items_to_buy.collect { |i| i.product.id.to_s }.join(':'))
  end

  # Return summary of cart contents as a string, used for active merchant transaction description
  def summary
    items_to_buy.collect { |i| "#{i.product.name} (#{i.product.id})" }.join(', ')
  end


  # The maximum number of recommendations to return from recommended_products, below:
  MAX_RECOMMENDATIONS_FOR_CART = 6

  # Return recommendations for other products based on the products in
  # the cart; only in-stock items are listed; valid options are
  # :limit, which defaults to MAX_RECOMMENDATIONS_FOR_CART, the limit
  # on the number of recommended items we'll return from this method.
  def recommended_products(options = {})

    options.assert_valid_keys(:limit)

    cart_products = cart_items.collect(&:product)
    recommendations = Hash.new(0)

    options[:limit] ||= MAX_RECOMMENDATIONS_FOR_CART

    # Get the recommendations for each product, and weight them by
    # index.
    cart_products.each do |product|
      product.product_recommendations.each_with_index do |recommended_product, i|
        recommendations[recommended_product] += (Product::MAX_PRODUCT_RECOMMENDATIONS  - i) if recommended_product.days_backorder == 0
      end
    end

    # Return the first recommendations, filtered for things already in the cart
    return (recommendations.sort { |a, b| b[1] <=> a[1] }.collect { |v| v[0] } - cart_products)[0, options[:limit]]
  end

  private


  # cart_inserter: a helper function for the add_ methods: puts
  # product in cart if not already there, allowing duplicate gift
  # cards but not duplicate products otherwise.  Does not raise
  # errors; the caller is responsible for this. Handles the
  # saved-for-later/wishlist functionality as well. --nzc Mon Feb 25
  # 15:27:27 2008
  def cart_inserter(product, options = {})
    options.assert_valid_keys(:save_for_later, :discount)

    # if the product is disabled for whatever reason, bail now.
    return unless product.display?
    cart_item = find_item_for_product(product)

    if cart_item
      # if this product is already in the cart, we still want to
      # update its saved_for_later status:
      cart_item.update_attributes(:saved_for_later => !options[:save_for_later].nil?,
                                  :discount => (options[:discount] or BigDecimal("0.0")))

      # We have a duplicate item: return unless it's a gift cert,
      # for which duplicates are allowed (and encouraged!:-)
      return if !product.is_a?(GiftCert)
    end

    # At this point, we know that either the product is not in the
    # shopping cart, or we have a gift certificate in hand.  In either
    # case, we need to make a new cart item, and place it in the
    # basket:
    cart_item = CartItem.for_product(product)
    cart_item.update_attributes(:saved_for_later => !options[:save_for_later].nil?,
                                :discount => (options[:discount] or BigDecimal("0.0")))

    # actually add the item to the cart.
    self.cart_items << cart_item
  end

  # Find an item from the cart, given the product, returning nil if not present
  def find_item_for_product(product)
    return self.cart_items.detect { |item| item.product == product }
  end

end

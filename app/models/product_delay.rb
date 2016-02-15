class ProductDelay < ActiveRecord::Base
  self.primary_key ="product_delay_id"

  attr_protected # <-- blank means total access

  #
  MAGIC_NEXT_ORDINAL = 999

  # number of days cutoff to remove items from category listings.
  #
  CUTOFF_TO_DISPLAY = 20

  # the number of days wait, at which we choose to warn customers and
  # ask to confirm before placing items in the cart.
  #
  CUTOFF_TO_WARN    = 30
end


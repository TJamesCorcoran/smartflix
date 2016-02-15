class ProductBundle < ActiveRecord::Base
  self.primary_key ="product_bundle_id"

  attr_protected # <-- blank means total access


  include BackorderTest

  has_many :product_bundle_memberships, :order => 'ordinal'
  has_many :products, :through => :product_bundle_memberships, :order => 'ordinal'

  def universities() [] end

  def premium?
    false
  end

  def price
    total = self.products.inject(0.0) { |sum,product| sum + product.price.to_f }
    return ApplicationHelper.round_currency(total * discount_multiplier)
  end

  def savings
    total = self.products.inject(0.0) { |sum,product| sum + product.price.to_f }
    return ApplicationHelper.round_currency(total - self.price)
  end
  
  def comparison_purchase_price
    self.products.inject(0.0){ |sum, product| sum + product.nonzero_purchase_price}
  end

  def comparison_rental_price
    price
  end

  def comparison_savings
    comparison_purchase_price - comparison_rental_price
  end

  def comparison_savings_percent
     "%2.0f" % (100 * (comparison_purchase_price - comparison_rental_price) / comparison_purchase_price )
  end

  
  def summary(len = 240)
    if description.size <= len
      summary = description
    else
      split = description.rindex(' ', len)
      split = len if split.nil?
      summary = description[0,split]
    end
    summary.gsub(/<[^>]*>/, ' ')
  end
end

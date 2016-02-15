class ProductSet < ActiveRecord::Base
  self.primary_key ="product_set_id"

  attr_protected # <-- blank means total access


  include BackorderTest

  has_many :product_set_memberships
  has_many :products, :through => :product_set_memberships, :order => 'product_set_memberships.ordinal'
  
  # Utility function to get the first product in the set
  def first
    products.first
  end

  def add_product(product, ordinal)
    ProductSetMembership.create!(:product => product, :product_set => self, :ordinal =>ordinal)
  end
end

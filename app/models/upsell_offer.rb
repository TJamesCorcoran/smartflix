class UpsellOffer < ActiveRecord::Base
  self.primary_key ="upsell_offer_id"

  attr_protected # <-- blank means total access

  belongs_to :customer
  belongs_to :reco,        :polymorphic => true
  belongs_to :base_order
  belongs_to :upsell_order

  def self.find_all_by_customer_id_and_reco(customer_id, reco)
    # We'd like to do UpsellOffer.find_all_by_customer_id_and_reco, but
    # activerecord doesn't DTRT with polymorphism there, so we have to feed in
    # the class and id separately, and if we do that, we have a problem because
    # the class we get out of a product when we write it to the poly table is "Product",
    # but if we try to read it with product.class, we get "Video", which sucks.
    effective_class = ( reco.is_a?(Product) ? Product : reco.class).to_s 
    self.find_all_by_customer_id_and_reco_type_and_reco_id(customer_id, effective_class, reco.id)

  end
end

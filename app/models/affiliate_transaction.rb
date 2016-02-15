class AffiliateTransaction < ActiveRecord::Base
  self.primary_key = "affiliate_transaction_id"
  attr_protected # <-- blank means total access

  # types:
  #    C - credit (customer!)
  #    R - revoke (customer cancelled an order
  #    P - payment to affiliate

  belongs_to :affiliate_customer, :class_name => 'Customer', :foreign_key => :affiliate_customer_id
  belongs_to :referred_customer, :class_name => 'Customer', :foreign_key => :referred_customer_id
  def name() referred_customer.andand.email end
end

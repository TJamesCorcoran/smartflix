class CustomerInitiatedEmail < ActiveRecord::Base
  self.primary_key = "customer_initiated_email_id"
  attr_protected # <-- blank means total access


  belongs_to :customer
  belongs_to :product

  validates_presence_of :recipient_email
  validates_format_of :recipient_email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  def save_and_send
    save && SfMailer.tell_a_friend(recipient_email, customer, message, product, self.id)
  end

end

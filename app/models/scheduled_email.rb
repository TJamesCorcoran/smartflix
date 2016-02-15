class ScheduledEmail < ActiveRecord::Base
  self.primary_key ="scheduled_email_id"

  attr_protected # <-- blank means total access

  belongs_to :customer
  belongs_to :product, :polymorphic => true


  TYPES = [:recommendation, :new, :browsed, 
           :univ_expire_cc_warn, :univ_expire_cc_charge,

           :univ_new_cust, :univ_old_cust]

  
  def self.note_emails_sent(customer, email_type, options)
    raise "illegal email_type" unless TYPES.include?(email_type)
    options.allowed_and_required( [:lis, :copies, :univ], [])
    products = nil
    if options[:lis]
      products = options[:lis].map(&:product)
    elsif options[:copies]
      products = options[:copies].map(&:product)
    elsif options[:univ]
      products = options[:univ].univ_stub.to_array
    else
      raise "no products specified"
    end


    products.each do |pp|
      ScheduledEmail.create!(:customer_id => customer.customer_id,
                             :email_type => email_type.to_s,
                             :product_id => pp.product_id)
    end
  end

end
 

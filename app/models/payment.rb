class Payment < ActiveRecord::Base
  self.primary_key = "payment_id"
  attr_protected # <-- blank means total access

  
  belongs_to :customer
  belongs_to :order
  belongs_to :credit_card
  has_one    :cc_expiration
  has_many   :payment_components
  has_one    :account_credit_transaction


  
  def expired?()    self.retry_attempts > PAYMENT_RETRY_MAX end
  
  def expired_message?() message.andand.match(/The credit card has expired/)  end
  
  
  
  PAYMENT_STATUS_IMMEDIATE = 1
  PAYMENT_STATUS_DEFERRED = 2
  PAYMENT_STATUS_RECURRING = 3
  PAYMENT_STATUS_DEFERRED_RESOLVED = 4
  
  PAYMENT_RETRY_MAX = 5

  scope :deferred, :conditions => "status = #{PAYMENT_STATUS_DEFERRED}"
  scope :failed,  :conditions => "! successful"
  scope :recent, :conditions => "TO_DAYS(updated_at) > TO_DAYS('#{Date.today << 1}')" 
  
  
  # if a payment is deferred (pending), and not yet complete, then it
  # may or may not be chargeable.  The criterion is, we allow three
  # charges on the first day, then wait a day, try again, wait a day,
  # and try one final time.  The code in charge_pending.rb limits the
  # number of retries to five..
  def chargeable?() 
    verbose = false

    return false if complete

    return false if order.nil?

    days = (Date.today - Date.parse(created_at.strftime("%Y-%m-%d")))

    num_charges_allowed =
    case days
    when  0..3 then   1
    when  4..7 then   2
    when  8..13 then  3
    when  14..30 then 4
    else           5
    end

    most_recent_cc = order.customer.most_recent_cc
   
    attempt_based_on_date   = num_charges_allowed > retry_attempts
    attempt_based_on_new_cc = (most_recent_cc && (most_recent_cc > updated_at)).to_bool

    if verbose
      puts "most_recent_cc = #{most_recent_cc}" 
      puts "attempt_based_on_new_cc = #{attempt_based_on_new_cc}" 
    end

    attempt_based_on_date || attempt_based_on_new_cc
  end


  def age()    (Time.now - self.updated_at)  end
  def fail!()    
    complete = successful = false
    save!
  end
  def succeed!()    self.update_attributes!(:complete => true, :successful => true)  end
  def good?()    complete && successful  end
  
  
  
  # Find a recent payment (last 1 minute) made by the supplied
  # customer, optionally required to match a cart hash
  def Payment.find_recent(customer, cart_hash = nil)
    conditions = if cart_hash
                   ['customer_id = ? AND cart_hash = ? AND (unix_timestamp(now()) - unix_timestamp(updated_at)) <= 60', customer.id, cart_hash]
                 else
                   ['customer_id = ? AND (unix_timestamp(now()) - unix_timestamp(updated_at)) <= 60', customer.id]
                 end
    Payment.find(:first, :conditions => conditions, :order => 'updated_at DESC')
  end
  
  def self.ERRORCHECK_no_overprocessing
    Payment.find(:all, :conditions => "retry_attempts >= 6 and TO_DAYS(created_at) >= TO_DAYS('2010-05-20')")
  end
  
end

require 'date'
class Date
  # want to use a has_many / finder_sql bit here, but that only works
  # if Date inherits from ActiveRecord ...and it doesn't

  def payments
    Payment.find_by_sql("select * from payments where DATE_FORMAT(created_at, '%Y-%m-%d') = '#{self}'")
  end


end


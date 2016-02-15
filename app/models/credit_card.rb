# We wrap an instance of ActiveMerchant::Billing::CreditCard (generated
# only on demand), which provides most of the functionality, but we use
# active record to save the card (encrypting the CC number with a public
# key to make it one way on the server).

class CreditCard < ActiveRecord::Base
  self.primary_key = "credit_card_id"
  attr_protected # <-- blank means total access

  attr_reader :number

  belongs_to :customer
  has_many :payments

  @number = nil

  # Since we want to use type not as active record intends, we need to tweak
  self.inheritance_column = "not_type"

  #----------
  # encrypt / decrypt / active merchant functionality
  #----------

  # Decrypt the credit card number; this only works on back end systems
  # where the decryption key is available
  def decrypted_number_doit
    Decryptor.decrypt_string(self.encrypted_number)
  end

  def decrypt_using_found_keys

    # Perhaps this CC is newly created. Maybe not even saved to db
    # yet!  If so, just return the CC number
    #
    return number if number

    decrypted_number_doit
  end


  # Decrypts the encrypted number into cleartext.  Not db backed (on purpose)!!!
  # Number is accessible in self.number
  #
  # In test fixtures, instead of storing an encrypted number, you can set 
  #   last_name: 'hacked <cardnumber>'
  #
  # carnumbers you might want to use:
  #    AMEX success:     370000000000002
  #    Discover success: 6011000000000012
  #    MC success:       5424000000000015
  #    Visa success:     4007000000027
  #    Failure:          4222222222222 (set price to desired error code)
  #
  # See also
  #    * self.test_card_good
  #    * self.test_card_bad
  #

  # XYZFIX P2 - this should really be moved to lib/encryptor.rb

  def decrypt_cc_number(private_key)
    @number = number
    if (Rails.env != "production")
      @number = $1    if last_name.match(/^hacked ([0-9]+)$/)
    end
    @number ||= private_key.andand.private_decrypt(Base64.decode64(encrypted_number)) 
  end
  

  # Wrap the number setting accessor so that an encrypted version gets stored
  def number=(number)
    @number = number
    self.encrypted_number = Encryptor.one_way_encrypt_string(number)
    self.last_four = number.to_s[-4..-1]
  end

  #----------
  # ???
  #----------

  # Wrap a few direct calls that should go to the active merchant object
  [:expired?, :errors].each do |method_name|
    define_method(method_name) { |*args| self.active_merchant_cc.send(method_name, *args) }
  end

  # in test mode we don't want to have to jump through hoops to make
  # sure that card numbers are valid, match CC type, etc.
  if Rails.env == "test"
    alias_method :original_valid?, :valid?

    define_method("valid?") {  |*args| return true }
  end

  # Allow the internal active merchant credit card to be accessed
  # (generating it on demand)
  def active_merchant_cc
    ActiveMerchant::Billing::CreditCard.require_verification_value = false
    @amcc ||= ActiveMerchant::Billing::CreditCard.new(:number => self.number, :brand => self[:brand],
                                                      :month => self.month, :year => self.year,
                                                      :first_name => self.first_name, :last_name => self.last_name)
  end



  #----------
  # display stuff
  #----------

  # for use in tvr-master's meta-programming: we display an object's 'name' if it has one
  def name()    "x#{last_four} expires #{month}/#{year}"  end

  def display_type
    CreditCard.type_for_display(self[:brand])
  end

  def display_string
    "Credit Card (#{display_type}) XXXX-XXXX-XXXX-#{last_four}"
  end


  #----------
  # date / expiration stuff
  #----------

  def expire_date
    # have to put in the day-of-the-month to make ruby 1.8.5 (neon) happy
    Date.strptime("#{year}-#{month}-01", "%Y-%m-%d").end_of_month
  end

  def charge_date_before_expire
    expire_date - 7
  end
  
  def last_two_months?
    Date.today <= expire_date &&
      Date.today >= (expire_date << 2)
  end

  def last_month?
    (Date.today.month == month) &&    (Date.today.year == year)
  end

  def last_week?(n = 1)
    last_month? && ( (Date.today + (7 * n)) > expire_date)
  end

  def extrapolated_expiration_to_try
    # if this card failed because of a bad address, or was declined, etc., refuse to
    # extrapolate an expiration date
    return  nil if ! most_recent_payment.andand.expired_message?

    last_tried = payments.map {|payment| payment.cc_expiration.andand.to_date}.compact.max ||  self

    [ (Date.from_month_and_year(last_tried.month, last_tried.year) >> 1).end_of_month, Date.today.beginning_of_month].max
  end


  #----------
  # working / not-working stuff
  #----------

  def last_msg
    # Some payments have a timestamp of "0000-00-00 00:00:00"
    # I don't know why.
    #
    # Around 25 Nov 2011 this started breaking the following comparison.
    # I don't know why.
    #
    # <sigh>
    payments.max_by {|x| x.created_at || DateTime.parse("1900-01-01") }.andand.message
  end

  # XYZFIX P1
  # We could allow CCs with last error msg of 'This transaction has been declined'
  # We prob want to retry such cards now and then. 
  #
  def any_chance_of_working?(with_expired = false)
    return false if expired? && ! with_expired
    
    ret = last_msg.nil? || 
      last_msg.empty? || 
      last_msg.match(/Payment gateway was unavailable|^An error occurred|This transaction has been approved/).to_bool ||
      last_msg.match(/A valid amount is required/) ||
      (last_msg.match(/The credit card has expired/).to_bool && with_expired) ||
      extra_attempts > 0
    return ret.to_bool
  end

  def decr_extra_attempts
    self.extra_attempts = [0, (self.extra_attempts - 1)].max
    save(:validate => false)
  end

  def incr_extra_attempts
    self.extra_attempts += 1
    save
  end
  
  def live?
    any_chance_of_working?
  end


  def last_charge_failed?
    (! payments.empty?)  && (! payments.last.status)
  end

  def most_recent_payment
    payments.max_by(&:created_at)
  end

  def expired_message?
    most_recent_payment.andand.expired_message?.to_bool
  end

  #----------
  # utils
  #----------

  def to_xml(options={})
    options[:except] ||= []
    options[:except] << :brand if !options[:except].include?(:brand)
    super(options)
  end

  # Utility method to set up a credit card given the user supplied
  # parameters and a customer, using secure methods of assignment: we
  # hand code the mass assignment because attr_accessible does not
  # appear to work for our hacked up CreditCard model, and we want to
  # maintain assignment security
  def self.secure_setup(credit_card_params, customer)
    credit_card = CreditCard.new(:number => credit_card_params[:number],
                                 :last_four => credit_card_params[:number].to_s[-4..-1],
                                 :month => credit_card_params[:month],
                                 :year => credit_card_params[:year],
                                 :customer => customer,
                                 :first_name => customer.billing_address.first_name,
                                 :last_name => customer.billing_address.last_name,
                                 :brand => CreditCard.lookup_type(credit_card_params[:number]))

    # for some weird reason these don't get set automatically
    credit_card.update_attributes(:created_at => Time.now, :updated_at => Time.now)
    return credit_card
  end

  private

  # Lookup the type of credit card based on the number
  def self.lookup_type(number)
    return case number
           when /^4[0-9]{12}([0-9]{3})?$/ then 'visa'
           when /^5[1-5][0-9]{14}$/ then 'master'
           when /^3[47][0-9]{13}$/ then 'american_express'
           when /^6011[0-9]{12}$/ then 'discover'
           else ''
           end
  end

  # Lookup the type of credit card based on the number, and return a string for display
  def self.lookup_type_for_display(number)
    return type_for_display(lookup_type(number))
  end

  def self.type_for_display(type)
    case type
    when 'visa' then 'Visa'
    when 'master' then 'MasterCard'
    when 'american_express' then 'AmericanExpress'
    when 'discover' then 'Discover'
    else ''
    end
  end

  #----------
  # testing
  #----------

  if (Rails.env != "production")

    # The last name contains the desired decrypted number between parens.
    # This interacts with decrypt_cc_number() which expects them.
    #
    def self.test_card_good
      cardnumber = "5424000000000015"
      cc = CreditCard.new(:month => 12,
                          :year => Date.today.year + 1,
                          :first_name => "John",
                          :last_name => "hacked #{cardnumber}",
                          :brand => "master",
                          :last_four => cardnumber[-4,4]
                          )
      cc.number = cardnumber
      cc
    end

    def self.test_card_bad
      cardnumber = "4222222222222"
      cc = CreditCard.new(:month => 12,
                          :year => Date.today.year + 1,
                          :first_name => "John",
                          :last_name => "hacked #{cardnumber}",
                          :brand => "master",
                          :last_four => cardnumber[-4,4])
      cc.number = cardnumber
      cc
    end
    
  end

end

require 'erb'
require 'money'

class ChargeEngine

  # for testing
  cattr_accessor :testing_return_value

  cattr_accessor :stats
  @@stats = Hash.new(0)
  @@stats[:charge_attempts] = @@stats[:charge_success] = @@stats[:charge_failures] = @@stats[:value_charged] = 0

  AUTHORIZENET_FLAT_FEE = 0.49
  AUTHORIZENET_PERCENT_FEE = 0.0

  MERCHANT_FLAT_FEE = 0.0
  MERCHANT_PERCENT_FEE = 0.0219

  TOTAL_FLAT_FEE = AUTHORIZENET_FLAT_FEE + MERCHANT_FLAT_FEE

  def self.estimated_processing_fees_from_success
    @@stats[:charge_success] * ( AUTHORIZENET_FLAT_FEE + MERCHANT_FLAT_FEE) +
      @@stats[:value_charged] * ( AUTHORIZENET_PERCENT_FEE + MERCHANT_PERCENT_FEE) 
  end

  def self.estimated_processing_fees_from_failed
    @@stats[:charge_failures] * ( AUTHORIZENET_FLAT_FEE + MERCHANT_FLAT_FEE)
  end

  def self.estimated_processing_fees_total
    estimated_processing_fees_from_success + estimated_processing_fees_from_failed
  end


  private
  
  # Perform an action (:charge or :credit) on a CC.
  # return either true or the error message
  #
  #  AMEX success:     370000000000002
  #  Discover success: 6011000000000012
  #  MC success:       5424000000000015
  #  Visa success:     4007000000027
  #  Failure:          4222222222222 (set price to desired error code) 
  #
  def self.act_on_credit_card(action, credit_card, dollar_amount, order_id, note, override_date = nil, original_payment = nil)
    # return [false, "CC already known to be dead"] if ! credit_card.live?
    
    # if credit_card.number
    #   decrypted_cc_number = credit_card.number
    # else
    #   # passphrase is either in config directory, or in your (human) head
    #   # passphrase-protected private key is in a file
    #   #
    #   decrypt_pem = nil
    #   file = "#{RAILS_ROOT}/config/cc_decrypt_keyphrase.rb"
    #   begin
    #     eval(File.read(file))
    #   rescue
    #     raise "no cc decrypt keyphrase file #{file}, or corrupt file"
    #   end
    #
    #   # XYZFIX P3: note that smartflixU expects the same file, but in your home dir
    #   # see smartflixU/lib/charge_card.rb
    #   file = "#{RAILS_ROOT}/config/tvr_datastorage_keys.pem"
    #   begin
    #     @private_key ||= OpenSSL::PKey::RSA.new(File.read(file), decrypt_pem)
    #   rescue
    #     raise "no private_key file, or corrupt file #{file}"
    #   end
    #
    #   decrypted_cc_number = credit_card.decrypt_cc_number(@private_key)
    # end
    
    decrypted_cc_number = credit_card.decrypt_using_found_keys

    customer = credit_card.customer
    if (customer.billing_address.nil?)
      return [false, "No billing addr for customer #{customer.email}, cc = x#{credit_card.last_four}"]
    end
    
    # Set up the gateway -- test mode is specified in the environment.rb config file
    login = SmartFlix::Application::AUTHORIZE_NET_API_LOGIN_ID
    password = SmartFlix::Application::AUTHORIZE_NET_TRANSACTION_KEY
    
    gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(:login => login,
                                                               :password => password)
    
    am_credit_card = ActiveMerchant::Billing::CreditCard.new(:number => decrypted_cc_number,
                                                             :month => override_date.andand.month || credit_card.month,
                                                             :year =>  override_date.andand.year  || credit_card.year,
                                                             :first_name => customer.billing_address.first_name,
                                                             :last_name => customer.billing_address.last_name)
    if action == :charge
      @@stats[:charge_attempts] += 1
      
      # Set up the credit card authorization options
      options = {
        :order_id => order_id,
        :description => note,
        :address => {},
        :currency => "USD",
        :billing_address => {
          :name     => "#{customer.billing_address.first_name} #{customer.billing_address.last_name}",
          :address_1 => customer.billing_address.address_1,
          :city     => customer.billing_address.city,
          :state    => customer.billing_address.state.code,
          :country  => customer.billing_address.country.name,
          :zip      => customer.billing_address.postcode
        },
      }
      
      payment = Payment.create!( :amount => dollar_amount,
                                 :amount_as_new_revenue => dollar_amount,
                                 :complete => 0,
                                 :status => nil,
                                 :successful => 0,
                                 :updated_at => Time.now(),
                                 :payment_method => "CreditCard",
                                 :order_id => order_id,
                                 :customer => customer)
      
      CcExpiration.create!(:payment => payment, 
                           :month => override_date.month,
                           :year => override_date.year) if override_date
      
      credit_card.payments << payment
      response = gateway.purchase(dollar_amount * 100 , am_credit_card, options)

      payment.update_attributes(:complete => 1, :successful => response.success?, :message =>response.message )
      
#RAILS3      credit_card.decr_extra_attempts
      
    elsif action == :refund
      options = { :card_number => decrypted_cc_number } #, :expiration_date => credit_card.expire_date  }
      identification = order_id
      response = gateway.credit(dollar_amount * 100, identification, options)
      response.message
    end
    
    if response.success? 
      @@stats[:charge_success] += 1
      @@stats[:value_charged] += dollar_amount
    else
      @@stats[:charge_failures] += 1
      return [false, response.message]
    end
    
    [true, credit_card.last_four]
  end
  
  
  public

  # if you know the credit card you want to use, feel free to call in here
  #
  
  def self.refund_credit_card(credit_card, charge_amount, order_id, note, override_date = nil, original_payment = nil)  
    ret = @@testing_return_value ||
      act_on_credit_card(:refund, credit_card, charge_amount, order_id, note, override_date, original_payment)  
  end

  # order_id is passed over to authorize.net
  def self.charge_credit_card(credit_card, charge_amount, order_id, note, override_date = nil)  
    ret = @@testing_return_value ||    
      act_on_credit_card(:charge, credit_card, charge_amount, order_id, note, override_date )  
    ret
  end

  private
  
  def self.act_on_customer(function, customer, price, order_id, note, with_guessed_expiration = false)


    errors = []
    ccs = customer.valid_cards(with_guessed_expiration)

    if with_guessed_expiration
      # Reload because in the tests we want to force failures.
      # Could do this conditionally for testing vs. production mode, but
      # (a) deploy what you test; (b) runs on backend; speed is not critical
      ccs = ccs.select {|cc| cc.reload.expired_message? } 
      return [ false, "guessed_expiration, but no expired cards"] if ccs.empty?
    end

    ccs.uniq_by(&:name).sort_by{ |cc| cc.expire_date}.reverse.each do |credit_card|

      override_date = credit_card.extrapolated_expiration_to_try if with_guessed_expiration

      ret = send(function, credit_card, price, order_id, note, override_date )
      last_four = credit_card.last_four || "????"
      return [ true, last_four ] if ret[0]
      errors << "x#{ credit_card.last_four || "????"} - #{ret[1]}"
    end
      
    return [ false, "no live cards: #{errors.join(', ')}" ]
  end
  
  public
  # TJIXFIX P2: it would be nice to have a void() func so that charges
  # (e.g. $2.99 late fee charges) could be reverted the same day or
  # the next day...
  

  # if you want to use whatever credit card you can, call in here
  #
  # on success returns: [ true,  last-four-digits-of-card ]
  # on failure returns: [ false, error-message ]
  #
  def self.refund_customer(customer, price, note, original_payment = nil)
    @@testing_return_value || 
      act_on_customer(:refund_credit_card, customer, price, 1, note, nil, original_payment )
  end
  
  # order_id is passed over to authorize.net
  def self.charge_customer(customer, price, order_id, note, with_guessed_expiration = false)
    @@testing_return_value || 
      act_on_customer(:charge_credit_card, customer, price, order_id, note, with_guessed_expiration )
  end

end

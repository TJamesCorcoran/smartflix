class Address < ActiveRecord::Base
  self.primary_key = "address_id"
  attr_protected # <-- blank means total access

  belongs_to :state
  belongs_to :country

  validates_associated :country
  validates_associated :state
  validates_length_of :address_1, :minimum => 5
  validates_length_of :city, :minimum => 3
  validates_length_of :first_name, :minimum => 2
  validates_length_of :last_name, :minimum => 2
  validates_presence_of :country, :message => 'must be selected'
  validates_presence_of :state, :message => 'must be selected'



  def validate
    if (!postcode.match(/^[0-9]{5}$/) && !postcode.match(/^[0-9]{5}[- ][0-9]{4}$/) &&
        !postcode.match(/^[a-z]\d[a-z][- ]?\d[a-z]\d$/i))
      if (country_id == 223)
        errors.add(:postcode, " is not valid, it should be 5 digits (or 5 digits plus a dash and 4 more digits)")
      elsif (country_id == 38)
        errors.add(:postcode, " is not valid, it should contain 6 characters, alternating letters and numbers")
      else
        errors.add(:postcode, " is not valid")
      end
    end
  end

  def full_name()    "#{first_name} #{last_name}"  end

  def to_s
    "#{first_name} #{last_name}\n#{address_1}\n#{(address_2.nil? || address_2 == address_1 || address_2.match(/^$/)) ? "" : "#{address_2}\n" }#{city} #{state_code}  #{postcode}#{country.name == "United States" ? "" : "\n#{country_name}"}"
  end
  def to_html()       to_s.gsub(/\n/, "<br>")  end
  def name()          to_html() end

  def canada?()       country_name == "Canada" end
  def us?()           country_name == "United States" end
  def apo?() 
    [7,9,11].include?(customer.shipping_address.state_id)
  end

  def customs?()      ! us?  end


  def state_code
    self.state.code
  rescue
    nil
  end

  def state_name
    self.state.name
  rescue
    nil
  end

  def country_name
    self.country.name
  rescue
    nil
  end

  if Rails.env != "production" 


    def self.addr_options
      options = {:first_name => "John" ,
        :last_name  => "Doe",
        :address_1  => "7 Central St" ,
        :address_2  => "Suite 140",
        :city      => "Arlington",
        :state_id     => 32, # "MA"
        :postcode  => "02476",
        :country_id   => 223  #"United States"
      }
      options
    end

    def self.test_shipping_addr
      ShippingAddress.new(addr_options)
    end
    
    def self.test_billing_addr
      BillingAddress.new(addr_options)      
    end
  end


end

# This CANNOT be run in production
Rails.env = 'development'

# Load rails
puts "Loading rails..."
require File.dirname(__FILE__) + '/../config/environment'

raise "DO NOT RUN IN PRODUCTION!" if Rails.env != 'development' || Rails.env != 'development'

class String
  # Replace a string with random data, keeping numbers as numbers,
  # letters as letters, capitalization, etc
  JUMBLE_SETS = {}
  [('0'..'9'), ('a'..'z'), ('A'..'Z')].each { |set| set.each { |char| JUMBLE_SETS[char] = set.to_a } }
  def jumble
    new = self.dup
    new.size.times do |i|
      new[i] = JUMBLE_SETS[new[i].chr][rand(JUMBLE_SETS[new[i].chr].size)] if JUMBLE_SETS[new[i].chr]
    end
    return new
  end
end

def active_record_jumble(model, methods)
  model.find(:all).each do |item|
    methods.each { |method| item.send("#{method}=".to_sym, item.send(method).to_s.jumble) if item.send(method) }
    yield item if block_given?
    item.save!
    puts "Completed #{model} #{item.id}" if item.id % 1000 == 0
  end
end

active_record_jumble(Address, [:city, :postcode, :address_1, :address_2, :first_name, :last_name])
active_record_jumble(CreditCard, [:first_name, :last_name]) { |cc| cc.number = '4111111111111111' ; cc.type = 'visa' ; cc.month = 1 ; cc.year = 2020 }
active_record_jumble(Customer, [:encrypted_ssn, :bio, :bio_html, :display_name, :first_name, :last_name, :email])
active_record_jumble(ContactMessage, [:message, :name, :ip_address, :email])
active_record_jumble(Suggestion, [:name, :ip_address, :email])

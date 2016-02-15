#! /usr/local/bin/ruby

# Utility script for running TVR related tasks via cron

Rails.env = "production"

puts "Loading rails..."

# Set up all the railsy stuff
require File.dirname(__FILE__) + '/../config/environment'
require 'application'


def decrypt_card(credit_card)

  # passphrase is either in config directory, or in your (human) head
  # passphrase-protected private key is in a file

  decrypt_pem = nil
  begin
    if (Rails.env == 'production')
      eval(File.read("#{Rails.root}/config/cc_decrypt_keyphrase.rb"))
    else
      decrypt_pem = "aestivine"
    end
  rescue
    LOGGER.warn "no cc decrypt keyphrase file, or corrupt file - will read manually"
  end
  @@private_key = OpenSSL::PKey::RSA.new(File.read("#{ENV["HOME"]}/datastorage_keys/tvr_datastorage_keys.pem"), decrypt_pem)

  credit_card.number =  @@private_key.private_decrypt(Base64.decode64(credit_card.encrypted_number))

end # def ChargePending.decrypt_card ...

puts "Loading credit cards..."

CreditCard.find_all_by_last_four(nil).each do |cc|

  begin
    # decrypt the card
    decrypt_card(cc) # compute the decrypted charge account number
  rescue Exception
    puts "Failed to decrypt number for card id# #{cc.id}"
    next
  end

  # fill the last four field
  cc.last_four = cc.number.to_s[-4..-1]
  # save the changes
  cc.save!
  puts "Finished processing card # #{cc.id}"

end


# how to run this script
#
#     RAILS_ENV=production rails runner bin/charge_for_lost.rb --customer <X> --copy <Y>
#

# BUGS:
#   * should try to increment expiration date on expired credit cards (??)
#   * the print out of "running total charged" is broken



require 'optparse'

flags = {}
flags[:stickerID] = Array.new
opts = OptionParser.new do |opts|
  opts.banner = "Usage: charge_for_overdue.rb [options] [ Rails.env=production] "
  opts.separator ""
  opts.on("--customer", "--customer [custID]", "  (specify customer)") { |custID| flags[:custID] = custID }
  opts.on("--copy",     "--copy     [stickerID]", "  (specify stickerID)")   { |stickerID| flags[:stickerID] << stickerID }
  opts.on("-h",         "--help",              "  (get help)")         { puts "charge_for_lost.rb --customer [custID] --copy [copyID] --copy [copyID] Rails.env=production" ;    exit }
end

opts.parse!(ARGV)

raise "--customer and --copy flags should be set" if ((flags[:custID].nil? || flags[:stickerID].empty?))

puts "running in #{Rails.env} mode as user '#{ENV["USER"]}' with logname '#{ENV["LOGNAME"]}'"

  
customer = Customer.find_by_customer_id(flags[:custID])
raise "customer does not exist" if customer.nil?

unless customer.valid_cards.any?
  puts "no valid cards" 
  customer.credit_cards.each do |cc|
    puts " * #{cc.name} - expired? #{cc.expired?} ; last_msg: #{cc.last_msg}"
  end
  return
end

copies = flags[:stickerID].map { |stickerID| Copy.find_by_sticker(stickerID) }
raise "need to specify a copy" if copies.empty? 
raise "one or more copies are bad" if ! copies.select{ |copy| copy.nil? }.empty?


lost_lis = []

copies.each { |copy| 
  li = copy.line_items.compact.select { |li| li.customer == customer && 
                                             (li.order.rental? || li.order.backend?) }.last
  if li.nil?
    puts "    ** no LI found for copy #{copy.sticker_id} ; skipping" 
  else
    lost_lis << li
  end
}


@@results = Hash.new { |hash, key| hash[key] = Array.new }
ret = OverdueEngine.lost_dvd_onecust(customer, lost_lis, {} )
puts "ret = #{ret.inspect}"

if ret.nil? 
  customer.credit_cards.each do |cc|
    puts " * #{cc.name} - expired? #{cc.expired?} ; last_msg: #{cc.last_msg}"
  end
end

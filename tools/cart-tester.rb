require 'strscan'
require 'logger'

AllowedTitles = {
  1 => [2601, 2731, 2734, 2737, 2738, 2884, 2920, 2921, 2922, 2923, 2924],
  2 => [14, 135, 137, 136, 18, 258, 253, 256, 257, 255, 259, 260, 261],
  3 => [41, 98, 89, 176, 494, 493, 492, 495, 496, 491, 497, 501, 503],
  4 => [1780, 1782, 1786, 1788, 1790, 1794, 1804, 1800, 1805, 1806],
  5 => [1153, 1833, 1837, 1839, 1994, 1836, 2022, 2296, 2297, 2298, 2299]
}

Sets = {
  1 => { 490 => [2306, 2309, 2307, 2308] },
  2 => { 489 => [2312, 2313, 2314] },
  3 => { 101 => [609, 610, 611, 612] },
  4 => { 102 => [613, 614, 615, 616] },
  5 => { 103 => [617, 618, 619, 620] }
}

Users = {
  1 => 'xxx_auto_1@smartflix.com',
  2 => 'xxx_auto_2@smartflix.com',
  3 => 'xxx_auto_3@smartflix.com',
  4 => 'xxx_auto_4@smartflix.com',
  5 => 'xxx_auto_5@smartflix.com'
}

BuyRegexp = %r(type="hidden" value="([0-9]+)" /><input src="/images/buttons/save_for_later_b.jpg)
SavedRegexp = %r(type="hidden" value="([0-9]+)" /><input src="/images/buttons/move_to_cart_b.jpg)

class Cart
  attr_accessor :buy, :saved
  def initialize(buy = [], saved = [])
    @buy = buy
    @saved = saved
  end
  def same(cart)
    cart.buy.sort == @buy.sort && cart.saved.sort == @saved.sort
  end
end

@local_cart = Cart.new

def get(url, ssl=false)
  log_action(url, "curl -k -s -i #{@cookie ? "-b _session_id=#{@cookie}" : ''} 'http#{ssl ? 's' : ''}://72.52.164.96/#{url}'")
  res = `curl -k -s -i #{@cookie ? "-b _session_id=#{@cookie}" : ''} 'http#{ssl ? 's' : ''}://72.52.164.96/#{url}'`
  log_action(url, res)
  return res
end

def post(url, ssl=false)
  res = `curl -k -d 'x=x' -s -i #{@cookie ? "-b _session_id=#{@cookie}" : ''} 'http#{ssl ? 's' : ''}://72.52.164.96/#{url}'`
  log_action(url, res)
  return res
end

def start_session
  print 'Starting session... '
  if (match = get('store').match(/Set-Cookie: _session_id=([0-9a-f]+);/))
    @cookie = match[1]
    puts @cookie
  else
    raise 'Could not get cookie'
  end
end

def add(id)
  puts "Adding #{id} to cart"
  post("cart/add/#{id}")
  @local_cart.buy << id.to_s
end

def add_set(id)
  puts "Adding set #{id} to cart (#{@sets[id].join(', ')})"
  post("cart/add_set/#{id}")
  @sets[id].each { |v| @local_cart.buy << v.to_s }
end

def delete(id)
  puts "Deleting #{id} from cart"
  post("cart/delete/#{id}")
  @local_cart.buy.delete(id.to_s)
  @local_cart.saved.delete(id.to_s)
end

def move(id)
  puts "Changing state of #{id} in cart"
  post("cart/move/#{id}")
  if (@local_cart.buy.include?(id.to_s))
    @local_cart.buy.delete(id.to_s)
    @local_cart.saved << id.to_s
  else
    @local_cart.saved.delete(id.to_s)
    @local_cart.buy << id.to_s
  end
end

def remote_cart
  c = Cart.new
  cart_page = get("cart")
  s = StringScanner.new(cart_page)
  while (item = s.scan_until(BuyRegexp))
    c.buy << item.match(BuyRegexp)[1]
  end
  s = StringScanner.new(cart_page)
  while (item = s.scan_until(SavedRegexp))
    c.saved << item.match(SavedRegexp)[1]
  end
  return c
end

def test_cart(expected = @local_cart)
  print 'Testing cart consistency... '
  if remote_cart.same(expected)
    puts 'OK!'
  else
    puts 'FAILED!'
    puts "Expected cart: #{expected.inspect}"
    puts "Remote cart: #{remote_cart.inspect}"
    exit
  end
end
    
def login()
  puts "Logging in as #{@user}"
  post("customer/login?password=#{@password}&email=#{@user}", true)
end

def logout
  puts "Logging out"
  get("customer/logout")
end

def checkout
  puts "Checking out"
  post('cart/checkout?credit_card\[number\]=4111111111111111&credit_card\[month\]=3&credit_card\[year\]=2010&terms_and_conditions=1', true)
end

def confirm_order(type = nil)
  print 'Confirming order... '
  if (match = get('cart/order_success', true).match(%r(<a href="/customer/order/([0-9]+)">)))
    order_id = match[1]
    order_page = get("customer/order/#{order_id}", true)
    bought = []
    s = StringScanner.new(order_page)
    while (item = s.scan_until(%r(<a href="/store/video/([0-9]+)/)))
      bought << item.match(%r(<a href="/store/video/([0-9]+)/))[1]
    end
    if (type == :set)
      # Munge each ID into the first ID in the set for comparison
      cart_buy = @local_cart.buy.collect { |id| @sets.values[0].include?(id.to_i) ? @sets.values[0][0].to_s : id }
      if (bought.sort == cart_buy.sort)
        puts "Set OK! (order #{order_id})"
        @local_cart.buy = []
        success = true
      end
    else
      if (bought.sort == @local_cart.buy.sort)
        puts "OK! (order #{order_id})"
        @local_cart.buy = []
        success = true
      end
    end
  end
  if (!success)
    puts 'FAILED!'
    puts "Local cart: #{@local_cart.inspect}"
    puts "Local cart mod for set: #{cart_buy.inspect}" if type == :set
    puts "Bought: #{bought.inspect}"
    puts "Order ID: #{order_id}"
    exit
  end
end

def log_action(action, string)
  @logger.info("==================================================================================")
  @logger.info(action)
  @logger.info("==================================================================================")
  @logger.info(string)
  @logger.info("")
end

user_num = ARGV.shift
if (!user_num || !Users[user_num.to_i])
  puts "Usage: #{$0} <#{Users.keys.min}-#{Users.keys.max}>"
  exit
end
@user = Users[user_num.to_i]
@password = 'password'
@vids = AllowedTitles[user_num.to_i]
@sets = Sets[user_num.to_i]

class MyLogFormatter < Logger::Formatter 
  MyLogFormat = "%s\n" 
  def call(severity, time, progname, msg )
    # If ever want to format time, use format_datetime(time)
    MyLogFormat % [msg2str(msg)] 
  end
end
@logger = Logger.new("#{user_num}.log")
@logger.formatter = MyLogFormatter.new 

start_session
login()

def pattern_1

  # add two titles, checkout
  these = @vids.sort_by { rand }[0,2]
  these.each { |v| add(v) }
  test_cart
  checkout
  confirm_order

end

def pattern_2

  # add three titles, save 1, checkout, add 1, move saved, checkout
  these = @vids.sort_by { rand }[0,4]
  these[0,3].each { |v| add(v) }
  test_cart
  move(these[1])
  test_cart
  checkout
  confirm_order
  test_cart
  move(these[1])
  add(these[3])
  test_cart
  checkout
  confirm_order

end

def pattern_3

  # Logout, add a title, login, check cart (to merge), checkout
  logout
  start_session
  add(@vids.sort_by { rand }[0])
  test_cart
  login()
  test_cart
  checkout
  confirm_order
  test_cart

end

def pattern_4

  # Same as above, but with no check cart after login (don't merge before checkout)
  logout
  start_session
  add(@vids.sort_by { rand }[0])
  test_cart
  login()
  checkout
  confirm_order
  test_cart

end

def pattern_5

  # Rent a set

  setid = @sets.keys.first
  add_set(setid)
  test_cart
  checkout
  confirm_order(:set)

end

def pattern_6

  setid = @sets.keys.first
  logout
  start_session
  add_set(setid)
  test_cart

  keeper = @sets[setid][1]
  move(keeper)
  test_cart

  login
  test_cart

  checkout
  confirm_order(:set)

  logout
  test_cart(Cart.new([], []))

  start_session
  new_item = @vids.sort_by { rand }[0]
  add(new_item)
  test_cart(Cart.new([new_item.to_s], []))

  login
  test_cart

  move(keeper)
  test_cart

  checkout
  confirm_order(:set)

end

(@vids + @sets.values[0]).each { |v| delete(v.to_s) }

while true

  pattern = "pattern_#{rand(6) + 1}"
  puts "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  puts "Running #{pattern}"
  puts "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
  send(pattern)

end

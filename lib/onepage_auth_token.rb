# Class to manage onepage auth tokens. These are used to provide
# authentication to a single page, with an expiration date. The format
# of the token is
#
#   <customer-id>-<expiration-day>-<mac>
#
# where the customer-id is the customers ID in the DB encoded in base
# 36, the expiration-day is the number of days since the epoch also
# encoded in base 36, and the mac is a hash of the first two items plus
# the URL for which the auth token is valid plus the MAC key.

class OnepageAuthToken

  # example usage:
  #     token = OnepageAuthToken.create_token(customer, 10, { :controller => 'contest',
  #                                                         :action => 'show',
  #                                                         :id => item.id }
  #                                           ) 
  #     <%= url_for :controller => :contest, :action => :show, :id => item.id, :token => token %>
  #
  # Note: 
  #    You can use the hash
  #         { :controller => "*", :action => "*" }
  #    to give unlimited access
  #
  def OnepageAuthToken.create_token(customer, days_valid, url_options)

    # Encode customer ID in base36
    customer_id = customer.id.to_s(36)

    # Generate expiration date, encoded as days since epoch in base36
    # XXXFIX P4: We're sure days is granular enough?
    expiration_day = ((Time.now.to_i / 86400) + days_valid).to_s(36)

    # Create a string representing url options in a normal form
    url = OnepageAuthToken.normalize_url(url_options)

    # Create the MAC of customer, expiration, url, and KEY
    mac = OnepageAuthToken.hash("#{customer_id}-#{expiration_day}-#{url}-#{SmartFlix::Application::SF_ONEPAGE_AUTH_KEY}")

    return "#{customer_id}-#{expiration_day}-#{mac}"

  end

  # Input:
  #   * a token
  #   * url options for the current URL (e.g. { :controller => "customer", :action =>"update", :id=>12 })
  #
  # Output:
  #    valid?   - the customer 
  #    invalid? - nil
  def OnepageAuthToken.validate(token, url_options)

    return nil if (!token)

    # Make sure it looks like the right kind of data
    fields = token.split(/-/)
    return nil if (fields.size != 3)

    # Check the expiration date
    expiration_day = fields[1].to_i(36)
    current_day = Time.now.to_i / 86400
    return nil if (current_day >= expiration_day)

    # Validate the MAC
    content = fields[0, 2].join('-')
    url1 = OnepageAuthToken.normalize_url(url_options)
    hash1 = OnepageAuthToken.hash("#{content}-#{url1}-#{SmartFlix::Application::SF_ONEPAGE_AUTH_KEY}")
    # puts "XXX-1: #{ (hash1 == fields[2]) ? 'true' : 'false'}"

    url2 = OnepageAuthToken.normalize_url({:controller => "*", :action => "*"})
    hash2 = OnepageAuthToken.hash("#{content}-#{url2}-#{SmartFlix::Application::SF_ONEPAGE_AUTH_KEY}")
    # puts "XXX-2: #{ (hash2 == fields[2]) ? 'true' : 'false'}"

    return Customer.find(fields[0].to_i(36))  if (hash1 == fields[2]) ||  (hash2 == fields[2]) 

    return nil

  end

  private

  def OnepageAuthToken.normalize_url(url_options)
    # Just sort all url components (converted to strings, stripping out any nils)
    url_options.values.select { |u| !u.nil? }.collect { |u| u.to_s}.sort.join(':')
  end

  def OnepageAuthToken.hash(string)
    # Return the first 80 bits of MD5, encoded in base 36
    Digest::MD5.hexdigest(string)[0,20].to_i(16).to_s(36)
  end

end

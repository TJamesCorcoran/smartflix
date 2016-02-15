module RandomChars

  # Generate a random claim code, one that is not used by any existing
  # coupons or gift certificates
  def RandomChars.generate_unique_claim_code
    code = nil
    while(code.nil?)
      # XXXFIX P3: Consider adding an initial character of G or C to make codes somewhat human parsable
      code = true_random_chars(8, ('A'..'Z').to_a.reject { |c| c == 'O' })
      code = nil if Coupon.find_by_code(code)
      code = nil if GiftCertificate.find_by_code(code)
    end
    return code
  end

  # Return the specified number of random characters, using an optional supplied charset
  def RandomChars.true_random_chars(num, charset=nil)

    # If no charset provided set one up: lowercase letters and numbers, but no 1
    # or l or o or 0 since they can be confused
    if (charset.nil?)
      charset = ('a'..'z').to_a + ('0'..'9').to_a
      charset.reject! { |c| c == 'l' || c == '1' || c == 'o' || c == '0' }
    end

    # Compute minimum number of bits needed to cover all input cases; use fact
    # that log2(x) = log(x) / log(2)
    bits_per_char = (Math.log(charset.size) / Math.log(2)).ceil
    bytes_per_char = (bits_per_char + 7) / 8

    collect = ''

    File.open("/dev/urandom", "r") do |r|

      while (collect.size < num)

        index = 0
        bytes_per_char.times { |i| index += (r.getc * (256 ** i)) }
        index &= ((2 ** bits_per_char ) - 1)
        next if (index >= charset.size)
        collect << charset[index]

      end

    end

    return collect

  end

end

class GiftCert < Product
  self.primary_key = "gift_cert_id"

  # for purposes of bulking together items into a shipment, a gift cert has no value
  # (until it's redeemed, it's just a 1 cent piece of plastic)
  def value() 0 end

  # shipping code wants this
  def product() self end

  # shipping code wants this
  def reserve()  end


end

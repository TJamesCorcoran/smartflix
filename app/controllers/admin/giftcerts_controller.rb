class Admin::GiftcertsController < Admin::Base

  # Sigh.
  # For historical reasons:
  #   * GiftCert        - a product <template> that you can buy
  #   * GiftCertificate - an instantiation of above, that we've sold to a customer

  def get_class() GiftCertificate  end

  def new
    if !( request.post? || request.put?)
      #----------
      # phase 1
      #
      @gift_certificate = GiftCert.new
    else
      #----------
      # phase 2
      #
      @gift_certificate = GiftCert.new
      begin
        template = GiftCert.find_by_product_id(params[:gift_cert][:id])
        
        univ_months = amount = nil
        if template.name.match(/University One Month/)
          univ_months = 1
        else 
          amount = template.name.gsub(/\$/, "").to_i
        end
        @item = GiftCertificate.create!(:amount => amount,
                                        :univ_months => univ_months,
                                        :used => false)
      rescue Exception => e
        flash[:error] = "product not created!!! - #{$!}"
      end
    end
  end



end

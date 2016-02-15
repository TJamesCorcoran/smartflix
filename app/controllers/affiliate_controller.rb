class AffiliateController < ApplicationController

  # Authenticate before every action
  before_filter :require_login, :except => :introduction

  # Make sure they've accepted the aggrement before letting them do anything (other than activate...)
  before_filter :check_agreement, :except => [ :agreement, :introduction ]

  def index

    @affiliate_link = url_for(:controller => 'store', :ct => "af#{@customer.id}", :trailing_slash => false)

    # Set up the images, for each size, with the user ID encoded in it (apache rewrites get the right image)
    image_sizes = ['120_060', '120_090', '300_250', '120_600']
    # Note: This :controller hack works to get the host / port correct, but feels, um, like a hack
    @images = image_sizes.collect { |size| url_for :controller => "banners/affiliate_#{size}.gif", :protocol => 'http://' }

    @current_balance = @customer.affiliate_balance
    @payments = @customer.affiliate_payment_transactions

    # Customers can submit their SSN on the index page
    if (request.post? && params[:customer] && params[:customer][:ssn])
      @customer.ssn = params[:customer][:ssn]
      if (@customer.save)
        flash.now[:ssn_message] = "Your SSN has been saved"
      else
        @customer.encrypted_ssn = nil
      end
    end

  end

  def agreement
    if (params[:commit] && params[:commit] == 'Accept Agreement')
      # They accepted agreement, save that and redirect
      @customer.affiliate = true
      if (@customer.save)
        redirect_to(:action => '')
      end
    elsif (@customer.affiliate?)
      # They've previously accepted the agreement, just redirect
      redirect_to(:action => '')
    end
  end

  def introduction
  end

  private

  # See if the user has agreed to the affiliate plan
  def check_agreement
    if (!@customer.affiliate?)
      redirect_to(:action => :agreement)
      return false
    end
  end

end

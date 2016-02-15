class TellAFriendController < ApplicationController

  def lightbox
    @product = Video.find(params[:id]) if params[:id]
  end

  def send_message

    emails = params[:to].split(/\s/).uniq.map do |email|
      CustomerInitiatedEmail.new(:customer => @customer, :product_id => params[:product_id], :recipient_email => email, :message => params[:message])
    end

    emails << CustomerInitiatedEmail.new(:customer => @customer,
                                         :product_id => params[:product_id],
                                         :recipient_email => @customer.email,
                                         :message => params[:message]) if params[:send_copy]

    quantity_sent = emails.select { |email| email.save_and_send }.size

    respond_to do |format|
      format.html { }
      format.js do
        render :update do |page|
          if quantity_sent - (params[:send_copy] ? 1 : 0) > 0
            page.replace_html 'tell-a-friend', :partial => 'email_sent', :locals => { :quantity => quantity_sent }
            page << "lightboxes[0].actions();" # Make sure the close button in the partial works on the lightbox
          else
            page << "$('tell-a-friend-buttons').show();$('tell-a-friend-sending').hide();"
            page.replace_html 'tell-a-friend-errors', '<p>Please specify valid email addresses</p>'
          end
        end
      end
    end

  end

end

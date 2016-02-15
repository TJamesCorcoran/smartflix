class AbandonedBasketEngine

  @@logger = method(:puts)   
  cattr_accessor :logger


  def self.abandoned_basket_emails
      
      day_threshold = (ENV['DAY_THRESHOLD'] || 7).to_i
      
      @@logger.call "Gathering data on customers who have non-empty carts, have not received abandoned basket emails before, and receive recommendation emails..."

      # XYZFIX P3: note that if a customer has multiple carts, we send him a different
      #             email for each.  Suck.
      carts = EmailPreferenceType.find_by_form_tag('recommended').customers.reject{|cust| cust.abandoned_basket_email}.map(&:carts).flatten

      carts = carts.reject{|cart|  cart.nil? || cart.cart_items.empty? || (cart.last_item_added_at && day_threshold.days.ago < cart.last_item_added_at)}
      
      @@logger.call "Found #{carts.size} non-empty carts..."
      
      carts = carts.select{|cart| cart.customer.unreturned_line_items.blank? }
      @@logger.call "#{carts.size} after pruning customers who have videos out..."
      
      if Rails.env == 'development'
        carts = carts[30,5]
        @@logger.call " ... truncating to 5 in non-production mode"
      end
      
      @@logger.call "Sending mail..."

      redo_count = 0
      carts.each do |cart|
        begin
          @@logger.call "#{cart.customer.email}..."
          cart.customer.create_abandoned_basket_email( :date_sent => Time.now.to_s(:db) )
          
          @@logger.call "Marked"
          SfMailer.abandoned_basket cart.customer, cart
          
          @@logger.call "Sent"
          # on success, reset the redo_count
          redo_count = 0
        rescue Net::SMTPServerBusy, Timeout::Error => e
          # on a given email attempt, give it 6 tries before re-throwing the error
          redo_count += 1
          raise e if redo_count > 6
          @@logger.call "timeout caught: redoing #{redo_count}"          
          sleep 5
          redo
        rescue Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
          # for these errors, don't bother trying again - maybe the addr we have is invalid ?
          @@logger.call "timeout caught: redoing #{redo_count}"          
          sleep 5
          next
        end
      end
      
      @@logger.call "Done."
    end
end

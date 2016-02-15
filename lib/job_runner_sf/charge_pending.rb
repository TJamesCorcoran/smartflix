# require "money"

# module JobRunner
#   class ChargePending


#     # outputs a list of "pending" charges which have completed in a "failed" state.
#     def ChargePending.listPendingFailed

#       failedCount = 0
#       LOGGER.info "List of payments pending but failed (complete but not successful):"
#       Payment.find_all_by_status_and_complete_and_successful(Payment::PAYMENT_STATUS_DEFERRED, true, false).each do |payment|
#         failedCount += 1
#         LOGGER.info " Payment # #{payment.id} for order # #{payment.order_id} failed."
#       end
#       LOGGER.info "Total pending failed payments = #{failedCount}"
#     end

#     # outputs a list of the "pending" charges which are incomplete (unprocessed)
#     def ChargePending.listPendingOpen
#       openCount = 0
#       LOGGER.info "List of payments pending and open (incomplete):"
#       Payment.find_all_by_status_and_complete(Payment::PAYMENT_STATUS_DEFERRED, false).each do |payment|
#         openCount += 1
#         LOGGER.info " Payment # #{payment.id} for order # #{payment.order_id} is incomplete."
#       end
#       LOGGER.info "Total pending open payments = #{openCount}"
#     end


#     ################################################################################################
#     # execute runs on the back end machine (neon) and uses the sshmon
#     # tunnel to connect to the front end machine to process pending
#     # charges.
#     ################################################################################################
#     def ChargePending.execute

#       payments_processed = 0
#       payments_held_for_retry = 0
#       payments_skipped_for_retry = 0
#       payments_failed = 0

#       # Find all the orders which have payments with the "pending"
#       # status, then deal with each:
#       Payment.find_all_by_status_and_complete(Payment::PAYMENT_STATUS_DEFERRED, false).each do |payment|

#         unless payment.chargeable?  # we might be waiting some time period to retry.
#           payments_skipped_for_retry += 1
#           next
#         end

#         customer = payment.customer
#         order_id = payment.order.id

#         next unless has_billing_address?(customer, order_id)

#         amount_to_charge = payment.amount_as_new_revenue

#         description = "Charge for order # #{order_id}"

#         # Find the most recently stored credit card for this customer.
#         card = customer.find_last_card_used
#         decrypt_card(card) # so we can charge it.
#         gateway = ActiveMerchant::Billing::Base.gateway(:authorized_net).new(:login => AUTHORIZE_NET_API_LOGIN_ID,
#                                                                              :password => AUTHORIZE_NET_TRANSACTION_KEY)
#         LOGGER.debug "Processing pending payment for customer ##{customer.customer_id}, order ##{order_id}."

#         # Set up the credit card authorization options
#         options = {
#           :order_id => order_id,
#           :description => description,
#           :address => {},
#           :billing_address => {
#             :name     => "#{customer.billing_address.first_name} #{customer.billing_address.last_name}",
#             :address1 => customer.billing_address.address_1,
#             :city     => customer.billing_address.city,
#             :state    => customer.billing_address.state.code,
#             :country  => customer.billing_address.country.name,
#             :zip      => customer.billing_address.postcode
#           }
#         }

#         # this next is to force the scope of charge_response, not to
#         # initialize it per se:
#         charge_response = ActiveMerchant::Billing::Response.new(false, "Default failure response. (INTERNAL ERROR)")

#         begin
#           unless (charge_response = charge_credit_card(gateway, card, amount_to_charge, options)).success?
#             # if we get here, a charge attempt has failed.  Log information about why.
#             LOGGER.info "Charge attempt for order # #{order_id} (card XXXX#{card.last_four}) failed due to #{charge_response.message}, retrying in 1 day"
#           end
#         rescue Exception => e
#           LOGGER.warn "charge_pending execute -- Exception (#{ e.inspect}) occurred during attempt to charge credit card, order id #{order_id}."
#         end

#         LOGGER.debug "charge attempt for order # #{order_id} (card XXXX#{card.last_four})" +
#           " #{charge_response.success? ? "was successful" : "failed due to #{charge_response.message}"}."

#         # bump the number of retry_attempts
#         payment.increment!(:retry_attempts)

#         begin
#           Payment.transaction do
#             if charge_response.success?
#               payment.succeed!

#             else
#               unless payment.expired?

#                 LOGGER.debug "charge_pending execute -- Failed payment held over for later retry."

#                 # allow this payment to coast and be retried -- update (just) the
#                 # retry_attempts and updated_at fields:
#                 payment.save!

#                 # This next email requires a customer interface to change the stored credit
#                 # card, and a link needs to be put in the message body to allow them to click
#                 # directly to the account maintenance page (via the login filter, of course.
# #                SfMailer.simple_message(customer.email, EMAIL_FROM, "Credit card charge failed (#{charge_response.message}) for your order #{order_id}",
# #                                       "We'll retry this charge in a day; you may change your credit card in your account page if you wish.")
#                 payments_held_for_retry += 1
#               else

#                 payment.fail!

#                 ## NZCFIX P3 refund any coupons used.

#                 # Also, credit back any account credit originally used (the transaction amount
#                 # will be negative, so this will add the credit back to the users' account.)
#                 if payment.account_credit_transaction
#                   customer.subtract_account_credit(payment.account_credit_transaction.amount)
#                 end

#                 LOGGER.warn "Failed to charge credit card after 4 attempts: #{order_id}"
#                 SfMailer.simple_message(TVR_CUSTOMER_SUPPORT,
#                                        SmartFlix::Application::EMAIL_FROM,
#                                        "Deferred payment on order #{order_id} failed after 4 charge attempts. (#{charge_response.message})", "")
#                 SfMailer.simple_message(customer.email, SmartFlix::Application::EMAIL_FROM,
#                                        "Your order # #{order_id} at Smartflix has failed.", "Your charge attempt failed due to #{charge_response.message}.  Please retry your order.")
#                 payments_failed += 1
#               end
#             end
#           end
#         rescue Exception => e
#           LOGGER.warn "charge_pending execute -- Error occurred during attempt to update payment status for order # #{order_id} in db:" + e.inspect
#           # If the charge succeeded, and the database update failed,
#           # we need to reverse the charge:
#           if charge_response.success?
#             LOGGER.warn "Since charge attempt for order # #{order_id} was successful, attempting to reverse the charge."
#             # First try voiding the transaction
#             void_response = gateway.void(charge_response.authorization)
#             # If that didn't work, try refunding via credit()
#             if (!void_response.success?)
#               credit_response = gateway.credit(amount_to_charge, charge_response.authorization, :card_number => card.number)
#               if !credit_response.success?
#                 LOGGER.warn "Failed to credit the charge back to #{order_id}"
#                 SfMailer.simple_message(SmartFlix::Application::TVR_CUSTOMER_SUPPORT,
#                                        SmartFlix::Application::EMAIL_FROM,
#                                        "Deferred payment on order #{order_id} failed",
#                                        "and we were unable to reverse the charges; investigate at credit processor.")
#               end
#             end
#           end
#         end # begin

#         payments_processed += 1
#       end # pending_payments.each do ...

#       LOGGER.info "charge_pending execute: #{payments_processed} deferred charges processed."
#       LOGGER.info "charge_pending execute: #{payments_held_for_retry} failed charges held over."
#       LOGGER.info "charge_pending execute: #{payments_skipped_for_retry} held (failed) charges skipped."
#       LOGGER.info "charge_pending execute: #{payments_failed} deferred charges completed, failed."
#       LOGGER.info "charge_pending execute exiting."

#     end # def ChargePending.execute


#     def ChargePending.has_billing_address?(customer, order_id)
#       if (customer.billing_address.nil?) # This should not be possible (checked in front end app and excluded)
#         LOGGER.warn "No billing address for customer #{customer.emailAddr}"
#         SfMailer.simple_message(SmartFlix::Application::TVR_CUSTOMER_SUPPORT,
#                                SmartFlix::Application::EMAIL_FROM,
#                                "No billing address for customer #{customer.last_name}, #{"customer.first_name"}",
#                                "Deferred payment on order #{order_id} failed because there is no billing address for the credit card.")
#         false
#       else
#         true
#       end
#     end

#     def ChargePending.decrypt_card(credit_card)
#       credit_card.number = credit_card.decrypt_using_found_keys
#     end


#     def ChargePending.charge_credit_card(gateway, credit_card, amount_dollars, options)
      response = gateway.authorize(amount_dollars * 100, credit_card.active_merchant_cc, options)
      if (!response.success?)
        LOGGER.warn "charge_credit_card: authorization failed."
        return response
      end
      response = gateway.capture(amount_dollars, response.authorization)
      # In development mode, pretend the charge succeeded; in production, tell the truth:
      if (Rails.env == 'production')
        LOGGER.warn "charge_credit_card: capture failed." unless response.success?
        return response
      else
        return ActiveMerchant::Billing::Response.new(true, "Dummy success response in testing.")
      end
    end # ChargePending.charge_credit_card ...
  end # class ChargePending ...
end # module JobRunner ...

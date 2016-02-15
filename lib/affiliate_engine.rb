# Note that info on rental prices, late prices, and replacement prices
# is all stored/computed inside the product object.

class AffiliateEngine
  @@logger = method(:puts)   
  cattr_accessor :logger

  def self.credit_affiliates
    
    @@logger.call "See the web page at https://smartflix.com/admin/affiliate_transactions\n"

    @@logger.call "Processing customer origin info looking for new affiliate credits"
    
    referrals = Origin.within_last_n_months(3).affiliates.with_customer

    @@logger.call "FOUND: #{referrals.size} recent referrals"
    
    # Figure out which affiliate referred each customer

    total_granted = 0.0
    referrals.group_by(&:customer).each_pair do |customer, referrals|

      # a customer might have several origins; we only care about the first
      ref = customer.origins.map { |o| o.updated_at.nil? ? (o.updated_at = "2000-01-01" ; o) : o }
      ref = ref.min_by(&:updated_at)

      # deal with broken data
      next if ref.first_uri.nil? 

      match = ref.first_uri.match(/ct=af([0-9]+)/)
      
      if (!match)
        @@logger.call " *** Could not find affiliate ID in URI #{ref.first_uri}"
        next
      end
      
      affiliate_id = match[1]
      affiliate = Customer.find(affiliate_id)

      # Do nothing if it's the affiliate placing the order
      customer_id = customer.customer_id
      next if affiliate_id.to_i == customer_id

      
      # 1. Sum all existing transactions by referred customer ID
      # 2. See if this customer has placed an uncancelled order
      # 3. If > 0 and true, or <= 0 and false, do nothing
      # 4. If > 0 and false, add a revocation of the appropriate amount
      # 5. If <= 0 and true, add a credit of the appropriate amount

      transactions = AffiliateTransaction.find_all_by_referred_customer_id(customer.id)
      transaction_sum = transactions.inject(0.0) { |sum, t| sum + t.amount }
      
      orders = Order.paid.for_cust(affiliate).some_uncancelled.some_nonreplacement
      order_p = orders.any?

      # customer has live order, and credit has been issued: next!
      if (transaction_sum > 0 && order_p)
        next
      end

      # customer has no live order, and credit has NOT been issued / has been rejected: next!
      if (transaction_sum <= 0 && !order_p)
        next
      end


      # customer has cancelled order, but credit has already been issued: revoke!
      if (transaction_sum > 0 && !order_p)
        AffiliateTransaction.create(:transaction_type => 'R',
                                    :affiliate_customer_id => affiliate_id,
                                    :referred_customer_id => customer_id,
                                    :amount => (transaction_sum * -1.0),
                                    :date => Date.today)
        @@logger.call "Revoked credit of $#{"%0.2f" % transaction_sum} for affiliate #{affiliate.email}"
        total_granted -= transaction_sum
        next
      end
      
      # customer has live order, but credit hasn't  been issued: issue!
      if (transaction_sum <= 0 && order_p)
        amount = 5.0

        univ_orders = orders.for_univ_any
        if univ_orders.any?
          next unless univ_orders.detect { |o| o.num_good_univ_payments >= 2 }
          amount = 20.0
        end

        AffiliateTransaction.create(:transaction_type => 'C',
                                    :affiliate_customer_id => affiliate_id,
                                    :referred_customer_id => customer_id,
                                    :amount => amount,
                                    :date => Date.today)
        @@logger.call "Granted credit of $#{"%0.2f" % amount} to affiliate #{affiliate.email} for customer #{customer.email}"
        total_granted += amount
      end
      
    end
    
    # Final report of totals, who has been payed what and who is owed what
    @@logger.call ''
    @@logger.call "Customer                    Payments  CurrentCredit"
    @@logger.call "-------------------------   --------  -------------"
    transactions = AffiliateTransaction.find(:all)
    transactions.group_by(&:affiliate_customer_id).each do |customer_id, transactions|
      customer = Customer.find(customer_id)
      payments_total = transactions.select { |t| t.transaction_type == 'P' }.sum(0.0, &:amount)
      payments_total *= -1.0 if payments_total < 0.0
      current_credit = transactions.select { |t| t.transaction_type != 'P' }.sum(0.0, &:amount) - payments_total
      pay_now = "<------- pay" if current_credit >= 50.0
      @@logger.call "%-25s   %8s       %8s %s" % [customer.email, "$%.2f" % payments_total, "$%.2f" % current_credit, pay_now]
    end
    @@logger.call ''
    @@logger.call '----------'
    @@logger.call "total granted today: #{total_granted}"
    @@logger.call ''
    
  end
end

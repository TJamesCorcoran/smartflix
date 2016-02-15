class MergePaymentCc < ActiveRecord::Migration
  def self.up
#    add_column(:payments, :message, :string, :null => true)

    puts "about to convert #{CcChargeStatus.count.commify} charge statuses to payments - may take ~5 minutes"
    CcChargeStatus.find(:all).each do |cc|
      payment =
      Payment.create!(:order_id              => nil,
                      :customer_id           => (cc.credit_card.andand.customer_id || 
                                                 200000), # fictional customer ... we need
                                                          # to put something here, even
                                                          # when we've got defective data
                      :payment_method        => cc.credit_card.andand.display_string || "Credit Card",
                      :credit_card_id        => cc.credit_card_id,
                      :amount                => cc.amount.to_f,
                      :amount_as_new_revenue => cc.amount.to_f,
                      :cart_hash             => nil,
                      :complete              => true,
                      :successful            => false,
                      :updated_at            => cc.updated_at,
                      :created_at            => cc.created_at,
                      :retry_attempts        => 0,
                      :message               => cc.message)

      cc.cc_expiration.andand.update_attributes(:payment => payment, 
                                                :cc_charge_status_id => nil)
    end

    CcChargeStatus.destroy_all
    remove_column(:cc_expirations, :cc_charge_status_id)
  end

  def self.down
    Payment.find(:all, :conditions => "! ISNULL(message)").each { |x| x.destroy }
    remove_column :payments, :message
    add_column(:cc_expirations, :cc_charge_status_id, :integer)
  end
end

class CcChargeStatus  < ActiveRecord::Base
  self.primary_key = "cc_charge_status_id"
  attr_protected # <-- blank means total access

  belongs_to :credit_card
  has_one    :cc_expiration

  def expired?
    message.match(/The credit card has expired/)
  end

  # for testing - hack an existing status (something we'd never do in production)
  if (Rails.env != "production")
    def expired!
      self.update_attributes!(:message => "The credit card has expired")
    end
  end


  def self.STATS_expense_CURRENCY(start, finish)
    ChargeEngine::TOTAL_FLAT_FEE * CcChargeStatus.count(:all, :conditions =>"created_at >= '#{start.to_s}' and created_at <= '#{finish.to_s}'")
  end

end

require 'date'
class Date
  # want to use a has_many / finder_sql bit here, but that only works
  # if Date inherits from ActiveRecord ...and it doesn't

  def cc_charge_statuses
    CcChargeStatus.find_by_sql("SELECT * FROM cc_charge_statuses cccs  WHERE TO_DAYS(created_at) = TO_DAYS('#{self}')")
  end

end


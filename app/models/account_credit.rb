class AccountCredit < ActiveRecord::Base
  self.primary_key = "account_credit_id"
  attr_protected # <-- blank means total access

  belongs_to :customer
  has_many :account_credit_transactions

  def to_s
    ret = []
    if univ_months && univ_months > 0
      ret << "#{univ_months_to_s} of SmartFlix University credit"
    end
    if amount > 0 || univ_months.nil? || univ_months == 0
      ret << "#{amount.currency} of account credit"
    end
    ret.to_sentence
  end

  def univ_months_to_s
    "#{univ_months} #{'month'.pluralize_conditional(univ_months)}"
  end

  def any?
    (univ_months && univ_months > 0) || amount > 0
  end
  
end

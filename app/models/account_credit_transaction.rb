class AccountCreditTransaction < ActiveRecord::Base
  self.primary_key = "account_credit_transaction_id"
  attr_protected # <-- blank means total access


  belongs_to :account_credit
  belongs_to :gift_certificate
  belongs_to :payment

end

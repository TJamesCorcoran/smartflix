class CcExpiration  < ActiveRecord::Base
  self.primary_key = "cc_expiration_id"
  attr_protected # <-- blank means total access

  belongs_to :payment

  def self.date_to_expir(date)
    CcExpiration.new(:month => date.month, :year => date.year)
  end

  def to_date
    Date.from_month_and_year(month, year)
  end
end

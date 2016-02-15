class Vendor < ActiveRecord::Base
  self.primary_key ="vendor_id"

  attr_protected # <-- blank means total access


#  has_many :adwords_ads, :as => :thing_advertised
  has_many :products
  belongs_to :vendor_mood
  has_many :vendor_order_logs, :through => :products

  validates_uniqueness_of :name, :message => "is a duplicate"

  validates_format_of :name,
         :with => %r{\.(com|org|net|us|ca|biz|tv|uk|nz|info)}i,
         :message => "must include a TLD"

  before_save   :capitalize

  def hostile?() vendor_mood_id == 1 end

  private
  def capitalize
    self.name = self.name.capitalize
  end

end

# represents the "master copy" of a newsletter

class Newsletter < ActiveRecord::Base
  attr_protected # <-- blank means total access
  
  has_many :sections, :class_name => 'NewsletterSection', :order => 'sequence'
  belongs_to :newsletter_category
  has_many :recipients, :class_name => 'NewsletterRecipient'
  
  
  
  # XYZFIX P3 - this is an ugly hack.  We want to do something
  # much more railsy to decouple it from application class "Order"
  #
  def orders
    Order.find_all_by_origin_code("smnl#{id}")
  end
  
  def value
    orders.map(&:profit).sum
  end
  
  def reset
    recipients.destroy_all
  end
  
  def count_failed
    recipients.count(:conditions => { :status => 'failed_to_send' })
  end
  
  def count_sent
    recipients.count(:conditions => { :status => 'sent' })
  end
  
  
  
  # depends on code in
  #     vendor/plugins/basichacks/lib/objecthack.rb
  def self.last_with_recipients
    self.find(:all, :order => "id desc").detect { |n| n.count_sent > 10 }
  end

end

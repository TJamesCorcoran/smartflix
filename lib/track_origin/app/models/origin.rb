class Origin < ActiveRecord::Base
  attr_protected # <-- blank means total access


# RAILS3  unloadable # necessary in devel: w/o this, 1st call to origin.customer() works, 2nd doesn't

  belongs_to :customer

  scope :within_last_n_months, lambda { |n| { :conditions => "TO_DAYS(updated_at) > TO_DAYS('#{Date.today << n}')"  } }
  scope :recent, :conditions => "TO_DAYS(updated_at) > TO_DAYS('#{Date.today << 1}')" 
  scope :affiliates, :conditions => "first_uri LIKE '%ct=af%'"
  scope :with_customer, :conditions => "customer_id"

  def self.map_customer_to_origin(customer, session)
    customer_id = customer.class == Fixnum ? customer : customer.id
    ActiveRecord::Base.connection.execute("update origins set customer_id = #{customer_id} where id = '#{session[:origin_id]}'")
  end

  # note that there are two session "ids":
  #   (1) the long string that we hand the webbrowser client and it hands back
  #   (2) the db id 
  #
  # This func uses the former
  #
  def self.get_all_from_session_id(id)
    return [] unless id
    Origin.find(:all, :conditions => "session_id = #{id}")
  end
end

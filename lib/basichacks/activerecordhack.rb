# require 'ActiveRecord::Base'
class ActiveRecord::Base

  scope :on_date,  lambda { |date| { :conditions => [ "DATE(created_at) = ?", date] }}
  scope :on_or_after_date,  lambda { |date| { :conditions => [ "DATE(created_at)  >= ?", date] }}
  scope :on_or_before_date, lambda { |date| { :conditions => [ "DATE(created_at)  <= ?", date] }}
  scope :between_dates, lambda { |before_date, after_date| { :conditions => [ "DATE(created_at)  >= ? AND DATE(created_at) <= ?", before_date, after_date] }}
  scope :in_month, lambda { |date| { :conditions => [ "DATE(created_at)  >= ? AND DATE(created_at) <= ?", date.first_of_month, date.last_of_month] }}

  attr_accessor :hi_tmp_store

  # Assume you've got a Person, and the Person has a House (via 'has_one' or 'belongs_to')
  # If House has lots of funcs that you want to proxy through Person (e.g. "address(), two_story?()" ),
  # you can do this:
  #
  # def Person
  #   has_one :house
  #   proxy_functions :house, [ :address, :two_story? ]
  # end
  #
  def self.proxy_functions(association_sym, functions)
    reflections = self.reflections.select {|key, val| [ :has_one, :belongs_to ].include?(val.macro) }
    reflections = reflections.map { |pair| pair[0] }
    raise "#{self.class_name} does not have access to #{association_sym}" unless reflections.include?(association_sym)
    functions.each do |f|
      define_method(f) { self.send(association_sym).andand.send(f) }
    end
  end

  def self.next_id
    Customer.connection.select_all("show table status like 'adwords_ads'")[0]["Auto_increment"].to_i
  end

  # Assume that you've skipped over a range of ids, preserving them for later use.
  # Get the next free ID in that range.
  #
  # Example usage: in SmartFlix, with the first rails website
  # (railscart) we skipped up to id = 1,000,000 for lineitems.
  # We copy down items from the website to the master db and preserve ids.
  # What ids do we use for new line items created via backend cust support tools?
  # We use ids in the reserved range.
  #
  def self.next_free_id_in_range(low, high)
    liid = self.find_by_sql("select max(#{self.primary_key}) as maxid from #{table_name} where #{self.primary_key} >= #{low}  and #{self.primary_key} <= #{high}")[0].maxid.to_i
    raise "exhausted space!!!" if liid == high
    (liid == 0) ? low : liid + 1

  end

  def self.create_with_id(options)
    raise "call with a hash, specify :id => XX" unless options.is_a?(Hash) && options[:id]
    id = options[:id]
    options.delete(:id)

    # ???FIX p4: XXX says: This order will create missing IDs at the end of the ID range, I'd
    # prefer a different approach (create a record manually and update it,
    # perhaps, not sure of the best approach).

    self.transaction do
      raise "item already exists with id #{id}" if ! find(:all, :conditions => "#{self.primary_key} = #{id}").empty?
      created = create(options)
      connection.execute("update #{self.table_name} set #{self.primary_key} = #{id} where #{self.primary_key} = #{created.id}")
    end
    
    find(id)
  end

  # Call it like this:
  #    Title.find(1).destroy_children(:copies)
  # or
  #    Title.find(1).destroy_children([:copies, :line_items, :vendor])
  def destroy_children(child_funcs)
    child_funcs.to_array.each do |child_func|
      # to_a added so that it works on has_one or has_many
      self.send(child_func).to_a.each(&:destroy)
    end
  end
  
  # usage:
  #
  #    ps = PotentialShipment[123].
  #    ps.destroy_self_and_children( [ :potential_items, :potential_gift_certs ])
  #
  def destroy_self_and_children(child_funcs)
    self.destroy_children(child_funcs)
    self.destroy
  end

  # This is something like O(n^2), and an 'explain' on the query reveals 'using filesort'
  # Thus, running it on more than 10 or 20k rows can take a LONG time
  def self.find_gaps(start_position = nil)
    start_position ||= max_primary_key - 10000
    start_position = start_position >=  1 ? start_position : 1
    ret =
    connection.select_all("SELECT a.#{primary_key}+1 AS `From`, 
                                  MIN(b.#{primary_key}) - 1 AS `To`
                    FROM #{table_name} AS a, #{table_name} AS b
                    WHERE a.#{primary_key} < b.#{primary_key} and a.#{primary_key} > #{start_position} and b.#{primary_key} > #{start_position}
                    GROUP BY a.#{primary_key}
                    HAVING a.#{primary_key} < `To`")
    ret = ret.map { |hash|  { :from => hash["From"].to_i, :to => hash["To"].to_i}}
    ret.select { |hash| (hash[:to] - hash[:from]) > 0 }
  end

  def self.max_primary_key
    ret = connection.select_all("select max(#{primary_key}) as max from #{table_name} ").first["max"].to_i
  end

  def self.most_recent_update
    DateTime.parse(LineItem.connection.select_value("select max(updated_at) from #{table_name}"))
  end

  # in rails 2.3.5 
  #     Customer[12]
  # did the same thing as
  #     Customer.find(12)
  # Restore that!
  #
  def self.[](id)    find(id)    end

end

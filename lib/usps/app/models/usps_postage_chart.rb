class UspsPostageChart < ActiveRecord::Base

  scope :for_date, lambda { |date| { :conditions => ['rate_start_date <= ? AND ( ISNULL(rate_end_date) OR rate_end_date >= ?)', date, date] } }


  #----------
  # top-level
  #----------

  def self.find_max_weight(usps_type)
    connection.select_value("select max(weight_oz) from #{table_name}").to_i
  end

  # according to the USPS, what does this package weigh?
  #   * round up to next nearest whole ounce
  #   * round up to next USPS bin (e.g. "16 oz or less, 24 oz or less...")
  #
  def self.usps_weight(weight_oz, usps_physical = "parcel", usps_class = "bound printed matter", date = nil, recover_error = false)
    weight_oz = weight_oz.ceil
    date ||= Date.today
    # why zone 1?
    # why not.  ...but we need to avoid DUPLICATEs on zone
    conditions = ["zone = 1 AND weight_oz >= ? AND usps_physical = ? AND usps_class = ?", weight_oz, usps_physical.to_s, usps_class.to_s]
    all_results = UspsPostageChart.for_date(date).find(:all, :conditions => conditions)
    unless all_results.any?
      return 64 if recover_error
      raise "no results" 
    end
    all_results.min_by(&:weight_oz).weight_oz
  end

  def self.search(usps_physical, usps_class, weight_oz, zone = nil, date = nil)
    weight_oz = weight_oz.ceil
    date ||= Date.today
    conditions = ["weight_oz >= ? and usps_physical = ? and usps_class = ?", weight_oz, usps_physical.to_s, usps_class.to_s]
    conditions[0] += zone ? " AND zone = #{zone.to_i}"  : " AND ISNULL(zone)"
    all_results = UspsPostageChart.for_date(date).find(:all, :conditions => conditions)
    all_results.min_by(&:weight_oz)
  end

  def self.cost(usps_physical, usps_class, weight_oz, zone = nil, date = nil)
    search(usps_physical, usps_class, weight_oz, zone, date).andand.price_cents
  end
    
end

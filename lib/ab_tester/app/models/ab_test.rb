class AbTest < ActiveRecord::Base

  attr_protected # <-- blank means total access  

  acts_as_notable

  has_many :ab_test_options
  has_many :ab_test_results

  validates_uniqueness_of :name

  scope :active, :conditions => { :active => true}
  scope :inactive, :conditions => { :active => false}

  scope :convert_by_default, :conditions => { :convert_by_default => true}
  scope :convert_by_explicit, :conditions => { :convert_by_default => false}

  scope :convert_location , lambda { |location| { :conditions => ["convert_location = ?", location] }}

  #----------
  # auto_admin
  #----------
  def self.advice_relations_unshown_via_admin
    [:ab_test_results]
  end

  #----------
  # class methods
  #----------
  def self.sym_to_s(sym)
    sym.to_s.camelize
  end

  def self.s_to_sym(s)
    s.underscore.to_sym
  end

  def self.find_by_sym(sym)
    find_by_name(sym_to_s(sym))
  end

  #----------
  # ???
  #----------
  def name_as_sym
    self.s.to_sym(name)
  end


  #----------
  # ???
  #----------



  def option_names
    ab_test_options.map(&:name)
  end

  def find_option_by_name(str)
    ab_test_options.find_by_name(str)
  end

  def self.complete_destroy(name)
    name = name.to_s.camelize # works even if user passed in string
    find_by_name(name).andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end

  # return a hash, mapping option names to values
  #
  # { :<option_1_name> => { :attempts => X, :conversions => Y, :conversion_rate => Z },
  #   :<option_2_name> => { :attempts => X, :conversions => Y, :conversion_rate => Z, :best => true },
  #    ... }
  #
  def quick_compare
    first_val = ab_test_options.first.ab_test_results.map { |r| r.value.to_f }.sum

    hh = {}

    best = ab_test_options.max_by { |opt| opt.conversion_rate}.name

    ab_test_options.each do |opt|
      name = opt.name
      
      rhs = { :conversions => opt.conversions, 
              :attempts    => opt.attempts,
              :conversion_rate => opt.conversion_rate }
      rhs[:best] = true if name == best
      hh[name] = rhs
    end
    hh
  end
#  include AbTestStats

  # Given two options (supplied as symbols), compare them statistically
  #
  # input:
  #    * string of option A (should be default / base)
  #    * string of option B (experimental new one)
  #    * confidence interval desired (NB: just use 95!)
  # 
  # ret: hash with keys
  #    * :conversion_center
  #    * :conversion_lower
  #    * :conversion_upper
  #    * :statistical_significance
  #
  def compare(base_str, variant_str, confidence = 95)

    base    = self.find_option_by_name(base_str)
    variant = self.find_option_by_name(variant_str)
    raise "Cannot find supplied A/B Test options" unless base && variant

    # Can't even perform the math if not enough data
    return nil unless a.conversions > 0 && b.conversions > 0

    # Lookup the correct value of z for the desired confidence interval
    # ref_z = { 99 => 2.577, 95 => 1.96, 90 => 1.645, 85 => 1.439, 80 => 1.282, 75 => 1.151}[confidence]
    # raise 'Invalid confidence interval requested' unless ref_z

    # # Compare the conversion percentage
    # result = OpenStruct.new
    # result.conversion_difference = b.conversion_rate - a.conversion_rate
    # plus_minus = ref_z * Math.sqrt(((a.conversion_rate * (1 - a.conversion_rate)) / a.attempts) +
    #                            ((b.conversion_rate * (1 - b.conversion_rate)) / b.attempts))
    # result.conversion_lower_confidence = result.conversion_difference - plus_minus
    # result.conversion_upper_confidence = result.conversion_difference + plus_minus

    # # Compare the resulting values of all conversions
    # result.value_difference = b.average_of_converted - a.average_of_converted
    # plus_minus = ref_z * Math.sqrt(a.variance_of_converted / a.conversions +
    #                            b.variance_of_converted / b.conversions)
    # result.value_lower_confidence = result.value_difference - plus_minus
    # result.value_upper_confidence = result.value_difference + plus_minus

    # # Compare the overall results as a percentage as compared to the first option
    # result.overall_difference = b.average - a.average
    # plus_minus = ref_z * Math.sqrt(a.variance / a.attempts + b.variance / b.attempts)
    # result.overall_lower_confidence = result.overall_difference - plus_minus
    # result.overall_upper_confidence = result.overall_difference + plus_minus
    # result.overall_difference /= a.average
    # result.overall_lower_confidence /= a.average
    # result.overall_upper_confidence /= a.average

#    return result

  end

  # which option has the best results?  Note: orthogonal to 'converted?'
  #
  def best_option
    ab_test_options.reject { |opt| opt.value_times_rate.nan? }.max_by(&:value_times_rate)
  end

  # which of the options have enough data that we're sure they converted?
  #
  def converged_options
    base_option = ab_test_options.first
    other_options = ab_test_options[1,99999]
    other_options.select { |opt| opt.attempts > 10 && opt.conversions > 2 }.select { |opt| opt.converged?(base_option) }
  end

  def converged?
    converged_options.any?
  end

  # how recently has a customer seen this test?
  #
  def last_result_at
    ab_test_results.last.andand.created_at
  end

  def turn_off
    update_attributes(:active => false)
    save!
  end

  def turn_on
    update_attributes(:active => true)
    save!
  end

  # If a test has converged, we probably want to terminate the test
  # and code the new goodness into the system for everyone.
  #
  # A cron job calls this.
  #
  def self.list_converted_but_still_active
    AbTest.active.select(&:converged?)
  end

end

module AbTestStats

  # number of folks who got this option
  def attempts
    @attempts ||= ab_test_results.count
  end
  def conversions
    # XXXFIX P2: Use named scopes when railscart rails version supports them
    @conversions ||= ab_test_results.count( :conditions => 'value > 0.0')
  end

  
  #----------
  #  conversion rates
  #----------
  def conversion_rate
    @conversion_rate ||= conversions.to_f / attempts.to_f
  end

  def std_error
    Math.sqrt(conversion_rate * (1 - conversion_rate) / attempts)
  end

  def conversion_rate_low_mid_high
    { :low => conversion_rate - std_error,
      :mid => conversion_rate,
      :high => conversion_rate + std_error
    }
  end

  def z_score(base_option)
    (base_option.conversion_rate - conversion_rate) / Math.sqrt( std_error ** 2 + base_option.std_error ** 2)
  end

  def p_value(base_option)
    Distribution::Normal.cdf(z_score(base_option))
  end

  def converged?(base_option, goal = 0.95)
    return false if conversion_rate.nan?

    p = p_value(base_option)
    p < (1 - goal) || p > goal
  end


  #----------
  #  ???
  #----------

  # total revenue delivered by people who saw this
  def total_value
    @total_value ||= ab_test_results.find(:all, :conditions => 'value > 0.0').to_a.sum(&:value).to_f
  end

  # average revenue delivered per customer who saw this
  def average
    @average ||= total_value / attempts
  end

  # average revenue delivered per customer who saw this AND CONVERGED
  def average_of_converged
    @average_of_converged ||= total_value / conversions
  end

  # def variance
  #   gem 'statarray', ">= 0.0.1"
  #   require 'statarray'
  #   @variance ||= ab_test_results.map { |r| r.value.to_f }.to_statarray.variance
  # end
  # def variance_of_converged
  #   gem 'statarray', ">= 0.0.1"
  #   require 'statarray'
  #   @variance_of_converged ||= ab_test_results.find(:all, :conditions => 'value > 0.0').map { |r| r.value.to_f }.to_statarray.variance
  # end

end

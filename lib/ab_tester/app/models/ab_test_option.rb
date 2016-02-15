class AbTestOption < ActiveRecord::Base

  attr_protected # <-- blank means total access  

  belongs_to :ab_test
  has_many :ab_test_results

  validates_uniqueness_of :name, :scope => :ab_test_id

  include AbTestStats

  def self.sym_to_s(sym)
    sym.to_s.camelize
  end

  def self.s_to_sym(str)
    str.underscore.to_sym
  end

  def name_as_sym
    AbTestOption.s_to_sym(name)
  end

  def avg_value
    conv = nil
    case ab_test.result_type
    when 'Integer', 'Fixnum' then conv = lambda { |x| x.to_i }
    when 'Float'             then conv = lambda { |x| x.to_f }
    when 'BigDecimal'        then raise "unsupported"
    else                          conv = lambda { |x| x }
    end


    ab_test_results.map { |r| conv.call(r.value) }.average
  end

  def value_times_rate
    avg_value * conversion_rate
  end

  def self.advice_relations_unshown_via_admin
    [:ab_test_results]
  end

end

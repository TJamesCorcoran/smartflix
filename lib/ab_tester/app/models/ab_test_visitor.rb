class AbTestVisitor < ActiveRecord::Base
  attr_protected # <-- blank means total access  

  has_many :ab_test_results

  belongs_to :customer # XYZ FIX P1: this is not the right way to do this

  def results
    ab_test_results.map { |result| [ result.ab_test.name, result.ab_test_option.name ] }.to_hash
  end

  def results_print
    ab_test_results.sort_by{ |abtr| abtr.ab_test_id}.each { |r| puts "#{sprintf('%-30s', r.ab_test.name)} --> #{sprintf('%-30s', r.ab_test_option.name)}" }
  end

end

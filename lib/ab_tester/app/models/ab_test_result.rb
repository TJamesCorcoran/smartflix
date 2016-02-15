class AbTestResult < ActiveRecord::Base
  attr_protected # <-- blank means total access  

  belongs_to :ab_test
  belongs_to :ab_test_option
  belongs_to :ab_test_visitor

  belongs_to :reference, :polymorphic => true

  def value
    return read_attribute(:value) unless respond_to?(:has_references) && has_references
    return read_attribute(:value).to_f + ab_test_result_references.to_a.sum(&:value)
  end
end

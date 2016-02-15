class AbTestResultReference < ActiveRecord::Base
  belongs_to :ab_test_result
  belongs_to :reference, :polymorphic => true
  def value
    reference.ab_test_value
  end
end

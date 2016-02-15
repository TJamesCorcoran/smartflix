class CancellationLog < ActiveRecord::Base
  self.primary_key = "cancellation_log_id"

  attr_protected # <-- blank means total access


  belongs_to :reference, :polymorphic => true

end

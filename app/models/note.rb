class Note < ActiveRecord::Base
  attr_protected # <-- blank means total access
  belongs_to :notable, :polymorphic => true
end

class State < ActiveRecord::Base
  self.primary_key ="state_id"

  attr_protected # <-- blank means total access

end

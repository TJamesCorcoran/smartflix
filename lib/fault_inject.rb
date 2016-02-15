module FaultInject

  # We could use a singleton object instead of a global variable, but
  # that's just semantic sugar - it's still a global.
  def self.allow(allowed_fault)
    throw $FAULT if $FAULT == allowed_fault && Rails.env == "test"
  end

  def self.allow_true(allowed_fault)
    return true if $FAULT == allowed_fault && Rails.env == "test"
    return false 
  end

end

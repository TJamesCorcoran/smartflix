include ActionView::Helpers::NumberHelper

class Float
  

  def nan_as_nil
    self.nan? ? nil : self
  end
  
end

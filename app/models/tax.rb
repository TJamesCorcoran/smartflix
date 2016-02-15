class Tax < PriceModifier
  self.primary_key ="tax_id"


  def display_string
    'State Sales Tax'
  end
end

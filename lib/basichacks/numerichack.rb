# from http://www.ruby-forum.com/topic/132357

include ActionView::Helpers::NumberHelper

class Numeric
  def percent
    sprintf("%0.2f %%", self * 100)
  end

  def round_to( decimals=0 )
    factor = 10.0**decimals
    (self*factor).round / factor
  end
  
  # from
  #   http://pleac.sourceforge.net/pleac_ruby/numbers.html
  def commify
    self.to_s =~ /([^\.]*)(\..*)?/
    int, dec = $1.reverse, $2 ? $2 : ""
    while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
    end
    int.reverse + dec
  end

  
  # for views, you can also use the stock method
  #    number_to_currency()
  def currency
    number_to_currency(self)
  end
  
  alias_method :to_currency, :currency

  def html_currency(supress_dot = false)
    dollars = self.to_i
    cents = sprintf("%2.0f", (self - dollars) * 100)
    "<span class='dollars'>$#{dollars}#{supress_dot ? "" : "."}</span><span class='cents'>#{cents}</span>"
  end

  def currency_nocents
    number_to_currency(self, :precision => 0)
  end

  # http://snippets.dzone.com/posts/show/593
  def ordinal
    self.to_s + ( (10...20).include?(self) ? 'th' : %w{ th st nd rd th th th th th th }[self % 10] )
  end

  # map 0 to nil, all other values to selves
  def to_numeric_or_nil
    self == 0 ? nil : self
  end

end

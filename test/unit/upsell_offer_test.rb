require 'test_helper'

class UpsellOfferTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def test_all
#     UpsellOffer.create(:customer_id => 1,
#                        :product_id => 1,
#                        :base_order_id => 1,
#                        :ordinal => 1);
#     UpsellOffer.create(:customer_id => 1,
#                        :product_id => 2,
#                        :base_order_id => 1,
#                        :ordinal => 2);
  end
end

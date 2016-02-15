require 'test_helper'

class GiftCertificateTest < ActiveSupport::TestCase

  def test_validate_univs
    gc = GiftCertificate.create(:code => "123", :amount =>12)
    assert gc.valid?

    gc = GiftCertificate.create(:code => "234", :univ_months => 1)
    assert gc.valid?, gc.inspect

    gc = GiftCertificate.create(:code => "234", :amount =>12, :univ_months => 1)
    assert ! gc.valid?
  end

end

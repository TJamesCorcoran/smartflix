require 'test_helper'

class AddressTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # Make sure we can get the state and country info
  def test_state_and_country
    a = Address.find(1)
    assert_equal('AL', a.state_code)
    assert_equal('Alabama', a.state_name)
    assert_equal('United States', a.country_name)
  end

  # Make sure the validations fire
  def test_validations
    a = Address.new
    a.first_name = 'X'
    a.last_name = 'Y'
    a.address_1 = 'Z'
    a.city = 'C'
    a.postcode = '1'
    assert !a.valid?
    # assert a.errors.invalid?(:first_name)
    # assert a.errors.invalid?(:last_name)
    # assert a.errors.invalid?(:address_1)
    # assert a.errors.invalid?(:city)
    # assert a.errors.invalid?(:postcode)
    # assert a.errors.invalid?(:state)
    # assert a.errors.invalid?(:country)
    a.first_name = 'Xavier'
    a.last_name = 'Yellownose'
    a.address_1 = 'Zero Fool St.'
    a.city = 'Cumberbund'
    a.postcode = '10000'
    a.state = states(:state1)
    a.country = countries(:canada)
    assert a.valid?
  end

end

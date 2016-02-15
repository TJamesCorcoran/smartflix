require 'date'
require File.dirname(__FILE__) + '/../../../../../test/test_helper'

class Package
  attr_accessor :ounces
  attr_accessor :zone
  def initialize(options)
    @ounces = options[:ounces]
    @zone = options[:zone]
  end
end




class PoundsAndZonesTest < ActiveSupport::TestCase

  def setup
    [ {:ounces =>1, :zone =>1},
      {:ounces =>12, :zone =>1},
      {:ounces =>13, :zone =>2},
      {:ounces =>14, :zone =>3},
      {:ounces =>15, :zone =>4},
      {:ounces =>17, :zone =>1},
      {:ounces =>25, :zone =>1} ].map { |pair| Package.new(pair) }
  end


  def test_generate_many
#    packages = setup()
#    UspsPermitImprint.generate_many_ps3605r_heavyink(packages)
  end


  # def test_ceil_oz
  #   packages = setup()
  #   lbs_and_zones_count = Hash.new { |hash, key| hash[key] = Hash.new(0) }
  #   packages.each do |package|
  #     lbs = UspsPostageChart.ceil_oz( package.ounces,  :usps_class => "bound printed matter", :usps_physical => "parcel")
  #     lbs_and_zones_count[ lbs ][ package.zone ] += 1
  #   end
  #   assert_equal({16=>{1=>2, 2=>1, 3=>1, 4=>1}, 24=>{1=>1}, 32=>{1=>1}}, lbs_and_zones_count)
  # end

  def test_different_rates_on_different_dates
    first_start  = Date.today - 10
    first_middle = Date.today - 5
    first_end    = Date.today - 11

    second_start  = Date.today
    second_middle = Date.today + 5
    second_end    = Date.today + 10

    third_start  = Date.today + 11
    third_middle = Date.today + 15
    third_end    = nil

    UspsPostageChart.create!(:usps_physical =>"parcel",
                               :usps_class =>"first", 
                               :weight_oz => 1,
                               :zone => nil,
                               :price_cents => 10,
                               :rate_start_date => first_start,
                               :rate_end_date => first_middle)

    UspsPostageChart.create!(:usps_physical =>"parcel",
                               :usps_class =>"first", 
                               :weight_oz => 1,
                               :zone => nil,
                               :price_cents => 20,
                               :rate_start_date => second_start,
                               :rate_end_date => second_middle)

    UspsPostageChart.create!(:usps_physical =>"parcel",
                               :usps_class =>"first", 
                               :weight_oz => 1,
                               :zone => nil,
                               :price_cents => 30,
                               :rate_start_date => third_start,
                               :rate_end_date => third_middle)

    assert_equal(10, UspsPostageChart.cost("parcel", "first", 1, nil, first_middle).price_cents)
    assert_equal(20, UspsPostageChart.cost("parcel", "first", 1, nil, second_middle).price_cents)
    assert_equal(30, UspsPostageChart.cost("parcel", "first", 1, nil, third_middle).price_cents)
  end

end

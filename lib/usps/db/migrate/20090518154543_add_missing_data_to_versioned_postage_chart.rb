class AddMissingDataToVersionedPostageChart < ActiveRecord::Migration
  def self.up

    oz_to_dollars = {  
      1 => 1.22,
      2 => 1.39,
      3 => 1.56,
      4 => 1.73,
      5 => 1.90,
      6 => 2.07,
      7 => 2.24,
      8 => 2.41,
      9 => 2.58,
      10=> 2.75,
      11=> 2.92,
      12=> 3.09,
      13=> 3.26 }
    
    oz_to_dollars.each_pair do |oz, dollars|
      UspsPostageChart.create!(:usps_physical =>"parcel",
                               :usps_class =>"first", 
                               :weight_oz => oz,
                               :zone => nil,
                               :price_cents => dollars * 100,
                               :rate_start_date => Date.parse('2009-05-11'),
                               :rate_end_date => Date.parse('2100-05-11'))
    end

  end

  def self.down
    UspsPostageChart.delete_all("rate_end_date = '2100-05-11' and usps_physical ='parcel' and usps_class = 'first' and weight_oz <= 13" )
  end
end

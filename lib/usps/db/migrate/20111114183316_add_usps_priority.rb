class AddUspsPriority < ActiveRecord::Migration
  def self.up

    [["flat rate box", "usps priority", 40,  495, nil, Date.parse("2007-01-01") ],
     ["flat rate box", "usps priority", 80, 1050, nil, Date.parse("2007-01-01") ],
     ["flat rate box", "usps priority",120, 1495, nil, Date.parse("2007-01-01") ]].each do |line|

      UspsPostageChart.create!(:usps_physical => line[0],
                               :usps_class=> line[1],
                               :weight_oz =>line[2], 
                               :price_cents =>line[3], 
                               :zone =>line[4], 
                               :rate_start_date =>line[5], 
                               :rate_end_date => nil)
    end
  end

  def self.down
    UspsPostageChart.find(:all, :conditions => "usps_physical = 'flat rate box'").each(&:destroy)
  end
end

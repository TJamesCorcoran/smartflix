class Usps2011PriceHike < ActiveRecord::Migration
  
  def self.up
    
    change_column :usps_postage_charts, :rate_end_date, :date, :null => true

    UspsPostageChart.connection.execute("update usps_postage_charts set rate_end_date = '2011-04-16' where rate_end_date = '2100-05-11' AND
                                        ((usps_physical = 'parcel' and usps_class = 'bound printed matter') OR
                                         (usps_physical = 'parcel' and usps_class = 'first') OR
                                         (usps_physical = 'flat'   and usps_class = 'first'))")
    
    # HI uses three categories:
    #   1) first/parcel                             
    #   2) first/flat                                
    #   3) parcel/bound printed matter               

    #----------
    # first / parcel
    #     http://www.usps.com/prices/_pdf/april172011/First-Class%20Mail%20-%20Retail.pdf
    oz_to_dollars = {  
      1 => 1.71,
      2 => 1.71,
      3 => 1.71,
      4 => 1.88,
      5 => 2.05,
      6 => 2.22,
      7 => 2.39,
      8 => 2.56,
      9 => 2.73,
      10=> 2.90,
      11=> 3.07,
      12=> 3.24,
      13=> 3.41 }
    
    oz_to_dollars.each_pair do |oz, dollars|
      UspsPostageChart.create!(:usps_physical =>"parcel",
                               :usps_class =>"first", 
                               :weight_oz => oz,
                               :zone => nil,
                               :price_cents => dollars * 100,
                               :rate_start_date => Date.parse('2011-04-17'),
                               :rate_end_date => nil)
    end
    
    
    #----------
    # first / flat
    #     http://www.usps.com/prices/_pdf/april172011/First-Class%20Mail%20-%20Retail.pdf
    #
    oz_to_dollars = {  
      1 => 0.88, # no change
      2 => 1.08, # 3 cents
      3 => 1.28, # 6 cents
      4 => 1.48, # etc
      5 => 1.68,
      6 => 1.88,
      7 => 2.08,
      8 => 2.28,
      9 => 2.48,
      10=> 2.68,
      11=> 2.88,
      12=> 3.08,
      13=> 3.28 }
    
    oz_to_dollars.each_pair do |oz, dollars|
      UspsPostageChart.create!(:usps_physical =>"flat",
                               :usps_class =>"first", 
                               :weight_oz => oz,
                               :zone => nil,
                               :price_cents => dollars * 100,
                               :rate_start_date => Date.parse('2011-04-17'),
                               :rate_end_date => nil)
    end
    
    # bound printed matter / parcel
    #
    lbs_choices = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    
    zone_to_oz_to_dollars = {  
      1 => [2.34, 2.34, 2.44, 2.55, 2.65, 2.76, 2.86, 2.97, 3.07, 3.28, 3.49, 3.70, 3.91, 4.12, 4.33, 4.54, 4.75,  4.96,  5.17],
      2 => [2.34, 2.34, 2.44, 2.55, 2.65, 2.76, 2.86, 2.97, 3.07, 3.28, 3.49, 3.70, 3.91, 4.12, 4.33, 4.54, 4.75,  4.96,  5.17],
      3 => [2.38, 2.38, 2.50, 2.62, 2.74, 2.86, 2.98, 3.10, 3.22, 3.46, 3.70, 3.94, 4.18, 4.42, 4.66, 4.90, 5.14,  5.38,  5.62 ],
      4 => [2.44, 2.44, 2.58, 2.72, 2.86, 3.00, 3.14, 3.28, 3.42, 3.70, 3.98, 4.26, 4.54, 4.82, 5.10, 5.38, 5.66,  5.94,  6.22 ],
      5 => [2.53, 2.53, 2.70, 2.87, 3.04, 3.21, 3.38, 2.55, 3.72, 4.06, 4.40, 4.74, 5.08, 5.42, 5.76, 6.10, 6.44,  6.78,  7.12 ],
      6 => [2.64, 2.64, 2.84, 3.05, 3.25, 3.46, 3.66, 3.87, 4.07, 4.48, 4.89, 5.30, 5.71, 6.12, 6.53, 6.94, 7.35,  7.76,  8.17 ],
      7 => [2.70, 2.70, 2.92, 3.15, 3.37, 3.60, 3.82, 4.05, 4.27, 4.72, 5.17, 5.62, 6.07, 6.52, 6.97, 7.42, 7.87,  8.32,  8.77 ],
      8 => [2.89, 2.89, 3.18, 3.47, 3.76, 4.05, 4.34, 4.63, 4.92, 5.50, 6.08, 6.66, 7.24, 7.82, 8.40, 8.98, 9.56, 10.14, 10.72  ]
    }
    
    zone_to_oz_to_dollars.each_pair do |zone, oz_to_dollars|
      
      0.upto(lbs_choices.size - 1 ) do |index|
        
        # puts "zone #{zone} index #{index}" 
        lbs = lbs_choices[index]
        oz = (lbs * 16).to_i
        dollars = oz_to_dollars[index]

        # puts "zone #{zone} / index #{index} / lbs #{lbs} / oz #{oz} / dollars #{dollars}"
        
        UspsPostageChart.create!(:usps_physical =>"parcel",
                                 :usps_class =>"bound printed matter", 
                                 :weight_oz => oz,
                                 :zone => zone,
                                 :price_cents => dollars * 100,
                                 :rate_start_date => Date.parse('2011-04-17'),
                                 :rate_end_date => nil)
      end
    end
    
  end
  
  def self.down
    UspsPostageChart.connection.execute("delete from usps_postage charts where ISNULL(rate_end_date)")
    change_column( :usps_postage_charts, :rate_end_date, :date, :null => true)
    
    UspsPostageChart.find_by_usps_physical_and_usps_class_and_weight_oz("parcel", "first", oz).update_attributes(:rate_end_date => '2100-05-11')
    UspsPostageChart.find_by_usps_physical_and_usps_class_and_weight_oz("flat", "first", oz).update_attributes(:rate_end_date => '2100-05-11')
    UspsPostageChart.find_by_usps_physical_and_usps_class_and_weight_oz("parcel", "bound printed matter", oz).update_attributes(:rate_end_date => '2100-05-11')
    
  end
  
  
end

class AddVersioningToPostageChart < ActiveRecord::Migration
  def self.up
    add_column :usps_postage_charts, :rate_start_date, :date, :null => false
    add_column :usps_postage_charts, :rate_end_date, :date, :null => false
    # Mark all existing data as old (covering all pre-existing time)
    UspsPostageChart.update_all("rate_start_date = '1900-01-01', rate_end_date = '2009-05-10'")
    # Now add the new data
    # Grabbed from http://www.usps.com/prices/first-class-mail-prices.htm
    oz_to_cents = {
      1 => 88, 2 => 105, 3 => 122, 4 => 139, 5 => 156, 6 => 173, 7 => 190, 8 => 207, 9 => 224, 10 => 241, 11 => 258, 12 => 275, 13 => 292
    }
    oz_to_cents.each do |oz, cents|
      UspsPostageChart.create!(:usps_physical => "flat", :usps_class => "first",
                               :weight_oz => oz, :price_cents => cents,
                               :rate_start_date => Date.parse('2009-05-11'),
                               :rate_end_date => Date.parse('2100-05-11'))
    end
    # Grab from http://www.usps.com/prices/downloadable-pricing-files.htm
    # ups = CsvParser.parse(File.read('usps-data.csv'))
    # ups.each { |ra| zmap = (1..8).map { |i| "#{i} => #{ra[[i-1,1].max]}" }.join(', ') ; puts "#{ra.first.to_f} => { #{zmap} }," } ; nil
    pounds_to_zones_to_dollars = {
      1.0 => {  1 => 2.33, 2 => 2.33, 3 => 2.37, 4 => 2.43, 5 => 2.52, 6 => 2.63, 7 => 2.69, 8 => 2.88 },
      1.5 => {  1 => 2.33, 2 => 2.33, 3 => 2.37, 4 => 2.43, 5 => 2.52, 6 => 2.63, 7 => 2.69, 8 => 2.88 },
      2.0 => {  1 => 2.43, 2 => 2.43, 3 => 2.49, 4 => 2.57, 5 => 2.69, 6 => 2.83, 7 => 2.91, 8 => 3.17 },
      2.5 => {  1 => 2.54, 2 => 2.54, 3 => 2.61, 4 => 2.71, 5 => 2.86, 6 => 3.04, 7 => 3.14, 8 => 3.46 },
      3.0 => {  1 => 2.64, 2 => 2.64, 3 => 2.73, 4 => 2.85, 5 => 3.03, 6 => 3.24, 7 => 3.36, 8 => 3.75 },
      3.5 => {  1 => 2.75, 2 => 2.75, 3 => 2.85, 4 => 2.99, 5 => 3.20, 6 => 3.45, 7 => 3.59, 8 => 4.04 },
      4.0 => {  1 => 2.85, 2 => 2.85, 3 => 2.97, 4 => 3.13, 5 => 3.37, 6 => 3.65, 7 => 3.81, 8 => 4.33 },
      4.5 => {  1 => 2.96, 2 => 2.96, 3 => 3.09, 4 => 3.27, 5 => 3.54, 6 => 3.86, 7 => 4.04, 8 => 4.62 },
      5.0 => {  1 => 3.06, 2 => 3.06, 3 => 3.21, 4 => 3.41, 5 => 3.71, 6 => 4.06, 7 => 4.26, 8 => 4.91 },
      6.0 => {  1 => 3.27, 2 => 3.27, 3 => 3.45, 4 => 3.69, 5 => 4.05, 6 => 4.47, 7 => 4.71, 8 => 5.49 },
      7.0 => {  1 => 3.48, 2 => 3.48, 3 => 3.69, 4 => 3.97, 5 => 4.39, 6 => 4.88, 7 => 5.16, 8 => 6.07 },
      8.0 => {  1 => 3.69, 2 => 3.69, 3 => 3.93, 4 => 4.25, 5 => 4.73, 6 => 5.29, 7 => 5.61, 8 => 6.65 },
      9.0 => {  1 => 3.90, 2 => 3.90, 3 => 4.17, 4 => 4.53, 5 => 5.07, 6 => 5.70, 7 => 6.06, 8 => 7.23 },
      10.0 => {  1 => 4.11, 2 => 4.11, 3 => 4.41, 4 => 4.81, 5 => 5.41, 6 => 6.11, 7 => 6.51, 8 => 7.81 },
      11.0 => {  1 => 4.32, 2 => 4.32, 3 => 4.65, 4 => 5.09, 5 => 5.75, 6 => 6.52, 7 => 6.96, 8 => 8.39 },
      12.0 => {  1 => 4.53, 2 => 4.53, 3 => 4.89, 4 => 5.37, 5 => 6.09, 6 => 6.93, 7 => 7.41, 8 => 8.97 },
      13.0 => {  1 => 4.74, 2 => 4.74, 3 => 5.13, 4 => 5.65, 5 => 6.43, 6 => 7.34, 7 => 7.86, 8 => 9.55 },
      14.0 => {  1 => 4.95, 2 => 4.95, 3 => 5.37, 4 => 5.93, 5 => 6.77, 6 => 7.75, 7 => 8.31, 8 => 10.13 },
      15.0 => {  1 => 5.16, 2 => 5.16, 3 => 5.61, 4 => 6.21, 5 => 7.11, 6 => 8.16, 7 => 8.76, 8 => 10.71 }
    }
    pounds_to_zones_to_dollars.each_pair do |pounds, zones_to_dollars|
      zones_to_dollars.each_pair do |zone, dollars|
        UspsPostageChart.create!(:usps_physical =>"parcel",
                                 :usps_class =>"bound printed matter", 
                                 :weight_oz => (pounds * 16),
                                 :zone => zone,
                                 :price_cents => dollars * 100,
                                 :rate_start_date => Date.parse('2009-05-11'),
                                 :rate_end_date => Date.parse('2100-05-11'))
      end
    end
  end

  def self.down
    UspsPostageChart.delete_all("rate_end_date = '2100-05-11'")
    remove_column :usps_postage_charts, :rate_start_date
    remove_column :usps_postage_charts, :rate_end_date
  end
end

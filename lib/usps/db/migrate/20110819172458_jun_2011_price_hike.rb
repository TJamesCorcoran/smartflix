class Jun2011PriceHike < ActiveRecord::Migration

  # NOTES for the next time we have to do this:
  #   1) wget the file
  #   2) pdf2text
  #   3) emacs: edit down to just the bound printed matter / parcel bits
  #   4) emacs: use macros to convert to the zone_to_oz_to_dollars hash
  #   5) steal the rest from here

  # http://pe.usps.com/cpim/ftp/manuals/dmm300/notice123.pdf

  def self.up
    
    # bound printed matter / parcel
    #
    lbs_choices = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    
    #-----
    # We get two things from the USPS data
    #  1) this chart
    #  2) the start date
    #-----    
    zone_to_oz_to_dollars = {  
      1=>[2.34, 2.34, 2.44, 2.55, 2.65, 2.76, 2.86, 2.97, 3.07, 3.28, 3.49, 3.70, 3.91, 4.12, 4.33, 4.54, 4.75, 4.96, 5.17],
      3=>[2.38, 2.38, 2.50, 2.62, 2.74, 2.86, 2.98, 3.10, 3.22, 3.46, 3.70, 3.94, 4.18, 4.42, 4.66, 4.90, 5.14, 5.38, 5.62],
      4=>[2.44, 2.44, 2.58, 2.72, 2.86, 3.00, 3.14, 3.28, 3.42, 3.70, 3.98, 4.26, 4.54, 4.82, 5.10, 5.38, 5.66, 5.94, 6.22],
      5=>[2.53, 2.53, 2.70, 2.87, 3.04, 3.21, 3.38, 3.55, 3.72, 4.06, 4.40, 4.74, 5.08, 5.42, 5.76, 6.10, 6.44, 6.78, 7.12],
      6=>[2.64, 2.64, 2.84, 3.05, 3.25, 3.46, 3.66, 3.87, 4.07, 4.48, 4.89, 5.30, 5.71, 6.12, 6.53, 6.94, 7.35, 7.76, 8.17],
      7=>[2.70, 2.70, 2.92, 3.15, 3.37, 3.60, 3.82, 4.05, 4.27, 4.72, 5.17, 5.62, 6.07, 6.52, 6.97, 7.42, 7.87, 8.32, 8.77],
      8=>[2.89, 2.89, 3.18, 3.47, 3.76, 4.05, 4.34, 4.63, 4.92, 5.50, 6.08, 6.66, 7.24, 7.82, 8.40, 8.98, 9.56, 10.14, 10.72 ]
    }
    start_date = Date.parse('2011-04-17')
    usps_physical = "parcel"
    usps_class = "bound printed matter"

    zone_to_oz_to_dollars[2] = zone_to_oz_to_dollars[1]

    zone_to_oz_to_dollars.keys.sort.each do |zone|

      puts "==== zone #{zone}"

      oz_to_dollars = zone_to_oz_to_dollars[zone]

      0.upto(lbs_choices.size - 1 ) do |index|
        
        lbs = lbs_choices[index]
        oz = (lbs * 16).to_i

        dollars = oz_to_dollars[index]

        puts "    * index #{sprintf('%5i', index)} / lbs #{sprintf('%5.2f', lbs)} == oz #{sprintf('%5i',oz)} / dollars #{dollars}"
        
        # Find the old rate, so we can patch it.
        #
        # * note that we pick a date in the old range
        # * note that a better design would be to not have
        #    rate_end_dates, but just begin dates ...the end date is
        #    pretty well implied by the begining of the succeeding
        #    rate!
        old = UspsPostageChart.find_postage_full(usps_physical, usps_class, oz, zone, (start_date - 1))
        if old
          old.update_attributes(:rate_end_date => (start_date - 1))
        else
          puts "ERROR: no prev data for usps_physical= #{usps_physical}, usps_class= #{usps_class}, oz= #{oz}, zone= #{zone}, start_date= #{start_date}"
        end

        UspsPostageChart.create!(:usps_physical =>"parcel",
                                 :usps_class =>"bound printed matter", 
                                 :weight_oz => oz,
                                 :zone => zone,
                                 :price_cents => dollars * 100,
                                 :rate_start_date => start_date,
                                 :rate_end_date => nil)
      end
    end
  end

  def self.down

    UspsPostageChart.destroy_all("rate_start_date = '2011-04-17'")

    # # find list of new data
    # list = UspsPostageChart.find(:all, :conditions => "rate_start_date = '2011-04-17'")
    
    # list.each do |nn|

    #   # hack the old data to remove the rate_end_date

    #   old = UspsPostageChart.find_postage_full(nn.usps_physical, nn.usps_class, nn.oz, nn.zone, start_date)
    #   if nn
    #     old.update_attributes(:rate_end_date => (start_date - 1))
    #   else
    #     puts "ERROR: no new data for usps_physical= #{usps_physical}, usps_class= #{usps_class}, oz= #{oz}, zone= #{zone}, start_date= #{start_date}"
    #   end
    # end
    
  end
end

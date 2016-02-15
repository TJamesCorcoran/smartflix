k# How to update for new forms from USPS
#      1) save new PDF forms from USPS into dir
#             vendor/plugins/usps/templates/
#      2) break multipage file apart 
#               pdftk <foo>.pdf  burst verbose
#      3) svn add files
#      4) update constants above
#      5) review forms, see if anything new is needed
#           * if so, add fields to both "data" and "placement" hashes (below)
#           * how to get X,Y offsets for placement hash?  Read on!
#
#  How to generate the X,Y offsets:
#      1) open up blank PDF in gimp
#      2) accept default 850 x 1100 pixels, resolution 1000
#      3) for each field, scroll mouse to correct location, note X and Y in bottom bar 
#      4) update values in funcs 
#            * generate_one_ps3605r_raw_01
#            * generate_one_ps3605r_raw_02
#            * etc

class UspsPermitImprint

  MIN_SHIPMENT_SIZE = 200
  
  FORM_PAGE_1_TEMPLATE = "#{File.dirname(__FILE__)}/../templates/ps3605_pg_0001.pdf"
  FORM_PAGE_2_TEMPLATE = "#{File.dirname(__FILE__)}/../templates/ps3605_pg_0002.pdf"

  CONTAINER_LABEL_TEMPLATE = "#{File.dirname(__FILE__)}/../templates/container_label.pdf"

  #----------
  #  low-level pixel head-achey stuff
  #
  #----------

  # What is the default pixels per inch that the unix 'convert' program uses?
  # From the man page
  DEFAULT_RESOLUTION = 72

  # If we use default from 'convert' we get grainy 
  # images when we pump PDFs from vector -> bit -> vector.
  # Preserve a b it more resolution.
  HI_RESOLUTION_INCREASE_FACTOR = 4 

  # So what command line argument in pixels-per-inch do we want to pass into 
  # 'convert' program?
  CONVERT_DENSITY_ARGUMENT = DEFAULT_RESOLUTION * HI_RESOLUTION_INCREASE_FACTOR

  # When a human is in the loop, calculating x,y offsets in the form
  # using Gimp, he's assuming a resolution of 1000 pixels (gimp
  # default?)
  #
  # Turns out this is wrong.
  #
  # We can either yell at people to specify some other default...or we can just 
  # adjust things inside.  Do the latter.
  # 
  GIMP_SCALING_FACTOR = 0.71

  # Conflate these two things:
  #    what factor do we need to use to adjust human-using-Gimp pixel offsets
  #    into high-resolution-PDF-in-convert offsets?
  SCALING_FACTOR = GIMP_SCALING_FACTOR * HI_RESOLUTION_INCREASE_FACTOR




  #----------------------------------------
  #  SMARTFLIX
  #----------------------------------------


  def self.generate_all_ps3600ez_smartflix(packages)
#      manifest = Hash.new  { |hash, key| hash[key] = Hash.new(0) }
#      packages.each { |pack| manifest[pack.usps_type][pack.usps_weight_lb] += 1 }
#      manifest.each_key do |type_str| 
#        manifest[type_str].each_pair { |weight, count| puts "#{type_str} - #{weight} lb - #{count} items"}
#      end
    throw "non flat detected" if packages.detect { |pack| pack.usps_type != :flat}
    throw "must have at least 1 package" if packages.size <= 0
    sum_weight_oz = packages.inject(0){ |sum,pack| sum + pack.usps_weight_oz }
    avg_weight_oz = 1.0 * sum_weight_oz / packages.size
    avg_weight_oz = 1.0 # <<<< XYZFIX P1
    rate = UspsPostageChart.cost(:flat, :first, avg_weight_oz).price_cents * 1.0 / 100
    self.generate_one_ps3600ez(:usps_type => :flat, :weight_lb_each => avg_weight_oz / 16, :quant => packages.size, :rate=> rate)
  end

  def self.generate_one_ps3600ez_smartflix(options)
    raise "options wrong" unless options.is_a?(Hash)
    required = [:usps_type, :quant, :rate, :weight_lb_each]
    raise "missing or extra args (args == #{required.inspect})" unless Set.new(options.keys) == Set.new(required)

    # our data that we want to flow into the form
    #
    usps_type          = options[:usps_type]
    rate               = options[:rate]
    rate_str           = "$ #{sprintf("%0.2f", rate)}"
    quant              = options[:quant]
    weight_lb_each     = options[:weight_lb_each]
    weight_lb_each_str = sprintf("%05.0f", weight_lb_each * 100000 )
    total_dollars      = "$ #{sprintf("%0.2f", quant * rate)}"
    

    # the layout of the ps3600ez form
    #
    x_y_placement =
    { :letter => { :rate        => { :x => 0, :y => 0},
                   :quant       => { :x => 0, :y => 0},
                   :total_price => { :x => 0, :y => 0} },

      :flat =>   { :rate        => { :x => 400, :y => 310},
                   :quant       => { :x => 460, :y => 310},
                   :total_price => { :x => 530, :y => 310} },

      :single_weight =>            { :x => 470, :y => 100},
      :total_postage =>            { :x => 530, :y => 330},
      :postage_due   =>            { :x => 530, :y => 380},
      :date          =>            { :x => 300, :y => 150},
      :total_pieces  =>            { :x => 470, :y => 170},
    }

    specs = []
    specs << [usps_type, :rate,         rate_str]
    specs << [usps_type, :quant,        quant]
    specs << [usps_type, :total_price,  total_dollars ]
    specs << [:single_weight,           weight_lb_each_str]
    specs << [:total_postage,           total_dollars]
    specs << [:postage_due,             total_dollars]
    specs << [:date,                    Date.today.to_s]
    specs << [:total_pieces,            quant]

    tempfile = "/tmp/#{String.random_alphanumeric}.pdf"
    convert_str = " #{UspsPermitImprint.build_convert_str(x_y_placement, specs)} #{File.dirname(__FILE__)}/../templates/ps3600ez_half_filled.pdf #{tempfile}"
    throw "failed to build .pdf using #{convert_str}" unless system(convert_str)
#     system ("evince #{tempfile}")
    tempfile
  end

  #----------------------------------------
  #  HEAVYINK
  #----------------------------------------

    # Down below, we need to generate one ps3605r per weight class.
    # So, iterate over packages, find their weight class, and construct
    # a 2-d array of zone-vs-lb, with the values being the count of packages
    #
  def self.get_ozs_and_zones_count(packages)
    ozs_and_zones_count = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    packages.each do |package|

      raise "package #{package.id} has bad zone" unless package.zone >= 0 && package.zone <= 8

      begin
        ozs_and_zones_count[ package.cooked_weight ][ package.zone ] += 1
      rescue
        # if a package is overweight then it's not going to go on the
        # invoice ... we'll do it some other way.
      end
        
    end

    ozs_and_zones_count
  end

  # The USPS requires us to put cardstock 'container labels' on our tubs.
  #
  # This generates them.
  #
  def self.generate_container_labels(packages)
    all_tmpfiles = []

    ozs_and_zones_count = get_ozs_and_zones_count(packages)

    ozs_and_zones_count.keys.each do |ounces|
      ozs_and_zones_count[ounces].keys.each do |zone|

        count = ozs_and_zones_count[ounces][zone]

        one_file = "/tmp/#{String.random_alphanumeric}.pdf"

        x_y_placement = { 
          :foo_1        =>      { :x => 100, :y => 200},
          :foo_2        =>      { :x => 100, :y => 300},
          :foo_3        =>      { :x => 100, :y => 400},
          :foo_4        =>      { :x => 100, :y => 500}
        }

        zone_txt = "1 & 2" if zone == 1 || zone == 2

        form_data = {
          :foo_1 => "LB:     #{ounces /  16.0}",
          :foo_2 => "   = : #{ounces} OZ",
          :foo_3 => "ZONE:   #{zone_txt}",
          :foo_4 => "COUNT:  #{count}" }

        convert_str = " #{UspsPermitImprint.build_convert_str(x_y_placement, form_data, 40)} #{CONTAINER_LABEL_TEMPLATE} #{one_file}"

        throw "failed to build container_label .pdf using #{convert_str}" unless system(convert_str)

        all_tmpfiles << one_file
      end
    end

    all_tmpfiles
  end
  
  # each package should support two methods:
  #  .ounces() - returns the weight in oz (numeric type expected)
  #  .zone()   - returns the USPS zone    (int expected)
  #
  def self.generate_many_ps3605r_heavyink(packages)
    
    ozs_and_zones_count = get_ozs_and_zones_count(packages)
    
    # OK, now for each weight class, we feed the zone-to-count index in, and get
    # one 3605r out.  The 3605r is returned as an array of /tmp files (prob 2 files per)

    # sort the keys so that we print these out in order
    files = ozs_and_zones_count.keys.sort.map { |oz|
        generate_one_ps3605r_heavyink(:single_weight_ozs => oz, 
                                      :zone_to_count => ozs_and_zones_count[oz])
    }.flatten

  end

  # generate one ps3065 for bound printed matter parcels
  #
  # General theory:
  #   * top-level func (this one!) generates all data, passes ALL data
  #        down to per-page funcs
  #
  #   * per-page funcs know about layout of specific page, expect
  #        correct data to arrive from above
  #
  # inputs:
  #   :single_weight_oz - a recognized BPM weight
  #   :zone_to_count     - a map of zones to count, e.g. { 1 -> 3, 2 -> 1 } means 
  #                         3 packages for zone 1 and
  #                         1 package for zone 2
  #
  # testing:
  #    [ file1, file2 ] = UspsPermitImprint.generate_one_ps3605r_heavyink(
  #                              :single_weight_ozs => 14,
  #                              :zone_to_count => { 1 => 10, 3 => 30, 4 => 40, 5 => 50, 6 => 60, 7 => 70 })
  # 
  def self.generate_one_ps3605r_heavyink(options)

    # puts"**************************************** #{options[:single_weight_ozs]}" 

    required = [ :single_weight_ozs, :zone_to_count ]
    raise "missing args (args == #{ (required - options.keys).join(', ')})" if (required - options.keys).any?
    raise "surplus args (args == #{ (options.keys - required).join(', ')})" if (options.keys - required).any?


    # let's set 0-item defaults for all zones. Makes code cleaner later.
    zone_to_count = options[:zone_to_count]

    # puts "1: zone_to_count == #{zone_to_count.inspect}" 

    # USPS conflates zones 1 and 2.  Down below, our form just has a slot for zone 1.
    zone_to_count[1] += zone_to_count[2].to_i
    zone_to_count.delete(2)


    # We're going to build a hash of form_data to feed into document.
    # 
    # Step 1: get info on packages, zones, etc. Put that in hash.
    #
    form_data = {}
    total_total = 0.0

    (1..8).each do |zone_num|
      begin
        count = zone_to_count[zone_num]
        # puts "----" 
        # puts "  * zone:count = #{zone_num} : #{count}" 

        price = UspsPostageChart.cost("parcel", "bound printed matter", options[:single_weight_ozs], zone_num).price_cents * 1.0 / 100
        total = price * count
        total_total += total
        
        form_data["zone_#{zone_num}_nonbarcode_price".to_sym] = price
        form_data["zone_#{zone_num}_nonbarcode_num".to_sym] = count
        form_data["zone_#{zone_num}_nonbarcode_total".to_sym] = total
      rescue Exception  => e        
        Mailer.deliver_message(EMAIL_TO_BUGS, EMAIL_FROM, "bug in USPS permit imprint" , e.inspect)
      end
    end      

    form_data[:total_total] = total_total

    total_count = options[:zone_to_count].values.sum

    #
    # Step 2: other data
    #
    form_data.merge!({
      :mailer_phone              => "781-316-2739",
      :mailer_email              => "xyz@smartflix.com",
      :mailer_addr               => ["7 Central St", "Suite 140", "Arlington MA 02476"].join("\n"),
      
      :mailing_usps              => "Arlington",
      :mailing_type_imprint      =>"X",
      :mailing_type_metered      =>"",      
      :mailing_permit_num        =>"PI-789",
      :mailing_permit_num_2      =>"PI-789",


      :mailing_postage_cat_flat  => "",
      :mailing_postage_parcel    => "X",

      :mailing_pack_based_count  =>"X",
      :mailing_pack_based_weight =>"",
      :mailing_pack_based_both   =>"",

      :mailing_date              =>                  Date.today.to_s,
      :mailing_weight_single_lb  =>      (options[:single_weight_ozs] / 16.0).to_s,
      :mailing_num_pieces        =>            total_count.to_s,
      :mailing_total_weight      =>          (options[:single_weight_ozs] * total_count / 16.0 ).to_s,

      :postage_parts_completed_a =>"X",

      :postage_affixed_type_cor  =>"",
      :postage_affixed_type_low  =>"",
      :postage_affixed_type_nei  =>"X",
      :postage_affixed_pieces    =>"0",
      :postage_affixed_dollars   =>"0.00",
      :postage_affixed_total     =>"0.00",

      :postage_total             => total_total,
      :postage_due               => total_total,
      
      :certification_sig         =>"#{File.dirname(__FILE__)}/../templates/xyz_signature.jpg",   # NOTE: an image file!
      :certification_name        =>"Xxx", 
      :certification_phone       =>"781-555-1212",

      :page_2_use_part_a         => "X" 
    })

    #
    # Step 3: generate PDF files
    #
    file_1 = generate_one_ps3605r_raw_01(form_data)
    file_2 = generate_one_ps3605r_raw_02(form_data)

    # return
    #
    # `evince #{file_1} #{file_2}` 
    [ file_1, file_2 ]
  end

  # generate page 2
  #
  def self.generate_one_ps3605r_raw_01(form_data)
    # the layout of the ps3605r form, page 1
    #
    x_y_placement =
      {
      :mailer_phone                     => { :x => 260, :y => 120},
      :mailer_email                     => { :x => 70, :y => 130},
      :mailer_addr                      => { :x => 50, :y => 150},
      
      :mailing_usps                     => { :x => 58, :y => 255},
      :mailing_type_imprint             => { :x => 113, :y => 280},
      :mailing_type_metered             => { :x => 113, :y => 293},
      :mailing_permit_num               => { :x => 60, :y => 330},
      :mailing_permit_num_2             => { :x => 126, :y => 484},


      :mailing_postage_cat_flat         => { :x => 220, :y => 268},
      :mailing_postage_parcel           => { :x => 226, :y => 292},

      :mailing_pack_based_count         => { :x => 220, :y => 338},
      :mailing_pack_based_weight        => { :x => 284, :y => 338},
      :mailing_pack_based_both          => { :x => 328, :y => 338},

      :mailing_date                     => { :x => 374, :y => 260},
      :mailing_weight_single_lb         => { :x => 382, :y => 300},
      :mailing_num_pieces               => { :x => 618, :y => 290},
      :mailing_total_weight             => { :x => 624, :y => 334},

      :postage_parts_completed_a        => { :x => 330, :y => 410},

      :postage_total                    => { :x => 693, :y => 435},
      :postage_due                      => { :x => 693, :y => 490},
      
      :certification_sig                => { :x => 64, :y => 790, :image => true, :x_size => 150, :y_size =>20},
      :certification_name               => { :x => 400, :y => 790},
      :certification_phone              => { :x => 711, :y => 790}
    }

    required = x_y_placement.keys

    raise "missing args (args == #{ (required - form_data.keys).join(', ')})" if (required - form_data.keys).any?

    # convert all the dollar values to $xx.yy format
    keys = [ :postage_affixed_dollars, :postage_affixed_total, :postage_due, :postage_total ]
    keys.each do |key|
      form_data[key] = sprintf("\\$%4.2f", form_data[key]) if form_data[key]
    end


    tempfile = "/tmp/#{String.random_alphanumeric}.pdf"
    convert_str = " #{UspsPermitImprint.build_convert_str(x_y_placement, form_data)} #{FORM_PAGE_1_TEMPLATE} #{tempfile}"
    throw "failed to build .pdf using #{convert_str}" unless system(convert_str)
    tempfile
  end

  # generate page 2
  #
  def self.generate_one_ps3605r_raw_02(form_data)
    # the layout of the ps3605r form, page 2
    #
    x_y_placement =
    { :page_2_use_part_a        =>      { :x => 40, :y => 75},

      :zone_1_nonbarcode_price  =>      { :x => 229, :y => 355},
      :zone_1_nonbarcode_num    =>      { :x => 346, :y => 355},
      :zone_1_nonbarcode_total  =>      { :x => 630, :y => 355},

      :zone_3_nonbarcode_price  =>      { :x => 229, :y => 378},
      :zone_3_nonbarcode_num    =>      { :x => 346, :y => 378},
      :zone_3_nonbarcode_total  =>      { :x => 630, :y => 378},

      :zone_4_nonbarcode_price  =>      { :x => 229, :y => 405},
      :zone_4_nonbarcode_num    =>      { :x => 346, :y => 405},
      :zone_4_nonbarcode_total  =>      { :x => 630, :y => 405},

      :zone_5_nonbarcode_price  =>      { :x => 229, :y => 430},
      :zone_5_nonbarcode_num    =>      { :x => 346, :y => 430},
      :zone_5_nonbarcode_total  =>      { :x => 630, :y => 430},

      :zone_6_nonbarcode_price  =>      { :x => 229, :y => 456},
      :zone_6_nonbarcode_num    =>      { :x => 346, :y => 456},
      :zone_6_nonbarcode_total  =>      { :x => 630, :y => 456},

      :zone_7_nonbarcode_price  =>      { :x => 229, :y => 480},
      :zone_7_nonbarcode_num    =>      { :x => 346, :y => 480},
      :zone_7_nonbarcode_total  =>      { :x => 630, :y => 480},

      :zone_8_nonbarcode_price  =>      { :x => 229, :y => 504},
      :zone_8_nonbarcode_num    =>      { :x => 346, :y => 504},
      :zone_8_nonbarcode_total  =>      { :x => 630, :y => 504},
    }

    required = x_y_placement.keys
    raise "missing args (args == #{ (required - form_data.keys).sort { |x,y| x.to_s <=> y.to_s }.join(', ')})" if (required - form_data.keys).any?

    # convert all the dollar values to $xx.yy format
    keys = (1..8).map { |x| [ "zone_#{x}_nonbarcode_price".to_sym,"zone_#{x}_nonbarcode_total".to_sym]}.flatten
    keys << :total_total
    keys.each do |key|
      form_data[key] = sprintf("\\$%4.2f", form_data[key]) if form_data[key]
    end

    # generate the PDF
    tempfile = "/tmp/#{String.random_alphanumeric}.pdf"
    convert_str = " #{UspsPermitImprint.build_convert_str(x_y_placement, form_data)} #{FORM_PAGE_2_TEMPLATE} #{tempfile}"
    throw "failed to build .pdf using #{convert_str}" unless system(convert_str)
    tempfile
  end

  #----------
  # Generate a string that serves as input for the ImageMagick
  # 'convert' utility that will place the specified text at the
  # specified locations
  #
  # inputs:
  #
  #   1) a x_y_placement specification (a tree structure implemented
  #      using hashes, where each leaf node is a 2-element hash with keys
  #      :x and :y )
  #  
  #   2) a data specification (an array where each element is an array
  #      specifying a path down the x_y_placement spec, and the final
  #      element is a text value)
  #  
  # output:
  #    ImageMagick command line (including invocation of binary PLUS cmd line args)
  #
  def self.build_convert_str(placement, data, pointsize = nil)
    pointsize ||= 10
    convert_str = "convert -density 288x288 -pointsize #{pointsize} -gravity NorthWest "

    placement.each_pair do |key, placement_hash|
      x = placement_hash[:x] * SCALING_FACTOR
      y = placement_hash[:y] * SCALING_FACTOR
      raise "no x/y spec for #{key}" unless x && y

      datum = data[key]
      raise "no data for #{key}" unless datum

      if placement_hash[:image]
        raise "no x_size" unless placement_hash[:x_size]
        raise "no y_size" unless placement_hash[:y_size]

        x_size = placement_hash[:x_size] * SCALING_FACTOR
        y_size = placement_hash[:y_size] * SCALING_FACTOR

        convert_str << "-draw \"image Over #{x},#{y} #{x_size},#{y_size} '#{datum.to_s}'\" "
      else
        convert_str << "-draw \"text #{x},#{y} '#{datum.to_s}'\" "
      end

    end
    convert_str
  end
  

end

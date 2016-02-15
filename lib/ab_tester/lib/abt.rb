module Abt

  #----------
  # find a "random" value for a given test
  #
  #----------

  # Given a test name, which option do we present to the user? 
  #
  # Input: 
  #  test_name - can be specified in a number of ways
  #              preferred is as a symbol in underscore-seperated
  #              lowercase (ie :border_color) which is automatically
  #              converted to the proper database string (in this case
  #              "BorderColor").
  #
  # Output:
  #      symbol specifying the option name (e.g :green)
  #
  # This is called either in a controller or view context (in which
  # case 'session' is present as a global) or in a model context (in
  # which case 'session' is present as a class variable).  If called
  # in a model context, pass in the session through the optional
  # second arg.
  #
  # 
  # allowed_options - This should ALMOST ALWAYS allowed to default as nil.
  #                   If it is set, it's an array of syms - the options that we can tolerate.
  #                   This is useful only when 2 tests are interdependent.  E.g.
  #                       profession   = { :mechanic | :priest }
  #                       num_children = { :zero | :one | :two | :lots }
  #                   In this case, we'd write:
  #
  #                       profession   = ab_test(:profession_test, session) 
  #                       if profession == :priest 
  #                          num_children = ab_test(:num_children, session, [:zero]) 
  #                       else
  #                          num_children = ab_test(:num_children, session) 
  #                       end
  #
  def ab_test(test_name, session, allowed_options_names = nil)

    verbose = false

    #----------
    # 1: setup
    #----------

    # find test
    #
    test_name_cooked = AbTest.sym_to_s(test_name)

    ab_test = AbTest.find_by_name(test_name_cooked)

    puts "ABT-1 #{test_name} / #{test_name_cooked} / #{ab_test.inspect}" if verbose

    #----------
    # 2: special / broken cases
    #----------

    # Defective? abort.
    #
    unless ab_test

      ExceptionNotifier::Notifier.exception_notification({},
                                                         RuntimeError.new("unknown ab test: #{test_name} ; either add test to DB or remove from codebase")
                                                         ).deliver if Rails
      raise "unknown test '#{test_name}'" if Rails.env.development?
      return nil
    end

    if ab_test.ab_test_options.empty?
      puts "    * nonexistant / inactive: #{ab_test.inspect} / #{session.inspect}" if verbose
      raise "no options for test '#{test_name}'" if Rails.env.development?
      return nil
    end

    if !ab_test.active? || session.nil?
      puts "    * nonexistant / inactive: #{ab_test.inspect} / #{session.inspect}" if verbose
      return ab_test.ab_test_options[0].name_as_sym # :default
    end

    if Rails.env.test?
      return ab_test.ab_test_options[0].name_as_sym # :default
    end

    # Robot? abort.
    if (RobotTest.is_robot?(nil, session)) 
      puts "    * robot" if verbose
      return ab_test.ab_test_options[0].name_as_sym # :default
    end

    # Overridden by devel bar?
    #
    override = session[:ab_test_settings].andand[test_name.to_sym]
    if override
      puts "    * override" if verbose
      return override 
    end
    puts "ABT-2 here! #{session.inspect}" if verbose

    #----------
    # 2.1 winnow down for special cases
    #----------

    # if caller hasn't restricted allowed options then ALL are allowed
    puts "ABT-1.1 #{allowed_options_names.inspect}" if verbose
    allowed_options_names ||= ab_test.ab_test_options.map(&:name_as_sym)
    puts "ABT-1.2 #{allowed_options_names.inspect}" if verbose

    # make sure user isn't allowing something that doesn't exist
    if allowed_options_names
      allowed_options = allowed_options_names.map { |opt_name| ab_test.ab_test_options.select { |to| to.name_as_sym == opt_name }}.flatten
      raise "illegal allowed options #{ (allowed_options_names - allowed_options.map(&:name_as_sym)).inspect }" if allowed_options_names.size > allowed_options.size
    else
      allowed_options = ab_test.ab_test_options
    end
    puts "ABT-1.3 #{allowed_options.inspect}" if verbose



    #----------
    # 3: normal case
    #----------

    #-----
    # 3-a: establish visit_id
    #-----
    unless session[:ab_test_visitor_id]
      session[:ab_test_visitor_id] = AbTestVisitor.create!.id 
    end
    visitor_id = session[:ab_test_visitor_id]
    puts "ABT-3 #{visitor_id}" if verbose

    #-----
    # 3-b: find prev result
    #-----
    ret = AbTestResult.find_by_ab_test_visitor_id_and_ab_test_id(visitor_id, ab_test.id) 
    test_option = ret.andand.ab_test_option

    # mostly a devel issue: what if we've got an option already picked that is not legal given other constraints?
    # answer: destroy it so as to repick
    puts "ABT-3.1 #{test_option.inspect}" if verbose
    if test_option && ! allowed_options.include?(test_option)
      ret.destroy
      test_option = nil
    end


    puts "ABT-3.2 #{test_option.inspect}" if verbose

    #-----
    # 3-c: if there was no prev query, make the decision now
    #-----

    unless test_option
      
      # only pick frm valid options (which is prob all of them)
      valid_options = ab_test.ab_test_options
      valid_options.select! { |opt| allowed_options.include?(opt) } if allowed_options

      puts "ABT-3.3 #{ab_test.inspect} " if verbose
      puts "ABT-3.3.1 #{valid_options.inspect} " if verbose

      # use modular math to pick from among them. Translate that into an ordinal
      puts "ABT-3.3.2 #{visitor_id.inspect} / #{ab_test.spacing} / #{valid_options.size}" if verbose
      option_num = (visitor_id / ab_test.spacing) % valid_options.size
      option_num = valid_options[option_num].ordinal

      puts "ABT-3.4 #{visitor_id} / #{ab_test.spacing} / #{valid_options.size} = #{option_num} " if verbose
      test_option = ab_test.ab_test_options.detect { |o| o.ordinal.to_i == option_num }
      puts "ABT-3.5 #{option_num} / #{test_option.inspect}" if verbose

      AbTestResult.create(:ab_test_visitor_id => visitor_id, 
                          :ab_test_id         => ab_test.id,
                          :ab_test_option_id  => test_option.id, 
                          :value              => ab_test.base_result)
    end 
    puts "ABT-5 #{test_option.inspect}" if verbose


    # DONE!
    #
    return test_option.name.underscore.to_sym

  end

  #----------
  # we've got a conversion - note that the test worked!
  #
  #----------

  # location - a string that tells us where we're getting called from.
  #            * If called from the 'new user signed up' code, then we
  #              look up all the default "signup" tests.  
  #            * If called from the 'item purchased' code, then we
  #              look up all the default "purchase" tests.  
  #            * etc.
  #
  # explicit_abts - 
  #
  # operation - either
  #                :set
  #                :increment 
  # value     - dollar value (or whatever other metric you're using)
  # reference - [ OPTIONAL ] polymorphic pointer to the a reference
  #
  # example usage:
  # 
  #   def customer_checkout
  #       cart_value = GraphicNovel.price
  #       ab_test_result_all_tests(:set, cart_value)  # <----
  #   end
  #
  def abt_note_all(location, explicit_abts, operation, value, reference = nil)

    tests = AbTest.active.convert_location(location).convert_by_default
    tests += explicit_abts
    tests.uniq!

    tests.each { |test| 
      abt_note_one(operation, test, value, reference) 
    }
  end

  # Update the result for a test, either by setting a new value or
  # incrementing an existing value. The arguments are the operation
  # (either :set or :increment), the name of the test where we want to
  # update the results (ie :border_color), and the value to use when
  # setting or incrementing. In the case of an increment the stored
  # existing result value is first converted to the type specified by
  # the test (Float, Integer, Fixnum, and BigDecimal are supported),
  # it's incremented, then converted back to a string and stored; we do
  # nothing if the visitor ID has not been set or if the test result was
  # never initialized; the new result value is returned

  # XXXFIX P2: Eventually redact the order_id concept and use reference everywhere

  def abt_note_one(operation, ab_test, value, reference = nil)

    # We might be called as part of a controller or a view, get the
    # session and request object right in either case
    local_session = defined?(session) ? session : @controller.session
    local_request = defined?(request) ? request : @controller.request

    visitor_id = local_session[:ab_test_visitor_id]

    raise "Invalid ab_test operation type" if ![:set, :increment].include?(operation)
    return nil if (RobotTest.is_robot?(local_request, session))
    return nil if  Rails.env != "test" && local_request && local_request.host.match(/(craftzine|makezine)/)
    return nil if visitor_id.nil?
    return nil if ab_test.nil?
    return nil if !ab_test.active?

    # At this pt we are merely updating AbTestResults that were
    # created when we earlier queried them.  If we didn't every query
    # on a particular AbTest, we don't want to update it (e.g. "If
    # help page A and B are available, and user views neither, don't
    # assign a value or an order_id to either!")

    result = AbTestResult.find_by_ab_test_visitor_id_and_ab_test_id(visitor_id, ab_test.id) 

    return nil if result.nil?
    raise "Incorrect type: #{ab_test.result_type} expected, #{value.class} provided (#{value}) for #{ab_test.name}" if ab_test.result_type != value.class.to_s

    case operation
    when :increment
      # Increment the value; we increment in the context of the type
      # specified in the test table; we don't do general purpose type
      # conversion, because that's heavier weight than needed, we just
      # handle the common expected cases

      case ab_test.result_type
      when 'Integer', 'Fixnum' then existing_value = result.value.to_i
      when 'Float'             then existing_value = result.value.to_f
      when 'BigDecimal'        then existing_value = BigDecimal(result.value.to_s)
      else                          existing_value = result.value
      end

      new_value = existing_value + value
    when :set

      new_value = value

    end
    # update the result with value and the order_id
    #

    # Not clear if this is supported or not.
    # See
    #   db/migrate/20090618194958_ab_test_result_references.rb
    # for now, leaving out
    #
    #  result.reference = reference     if reference
    result.value = new_value
    result.save!

    return new_value

  end

  def self.map_customer_to_abtest(customer, local_session)
    ab_v_id = local_session[:ab_test_visitor_id]
    return if ab_v_id.nil?
    AbTestVisitor.find(ab_v_id).andand.update_attributes(:customer_id => customer.id)
  end

  #----------
  # admin - for devel_bar
  #
  #----------

  def get_all_settings()
    local_session = defined?(session) ? session : @controller.session
    return {} unless  local_session[:ab_test_visitor_id]
    AbTestResult.find_all_by_ab_test_visitor_id(local_session[:ab_test_visitor_id], :include => [ {:ab_test => :ab_test_options }, :ab_test_option]).map {|res| 
      [ res.ab_test, res.ab_test_option ]
    }.to_hash
  end

  def get_all_options(testname)
    AbTest.find_by_name(testname, :include => [:ab_test_options]).ab_test_options.map {|o| o.name}
  end

  # Force the value of an ab_test to be something particular.
  # Useful in circumstances like: 
  #   (1) we're running an a/b test of the price of something; ** AND **
  #   (2) we want to run a print ad that toutes the lower price
  #   (in which case we use routes to map the url to a trampoline which bangs this func)

  def ab_test!(test_name, value)
    test_name = test_name.to_s.camelize 
    value     = value.to_s.camelize     
    local_session = defined?(session) ? session : @controller.session

    local_session[:ab_test_visitor_id] ||= AbTestVisitor.create.id
    visitor_id = local_session.andand[:ab_test_visitor_id];
    raise "error!  no visitor_id" unless visitor_id

    test = AbTest.find_by_name(test_name)
    raise "error!  no test found for #{test_name}" unless test

    option = test.ab_test_options.select { |opt| opt.name == value}
    raise "error!  no test option #{value} found for #{test_name}" unless option && option.any?
    raise "error!  multiple test options #{value} found for #{test_name}" unless option.size == 1
    option = option.first


    result = AbTestResult.find_by_ab_test_visitor_id_and_ab_test_id(visitor_id, test.id)

    if result
      result.ab_test_option_id = option.id
      result.save!
    else
      result = AbTestResult.create!(:ab_test_visitor_id => visitor_id, 
                                    :ab_test_id =>         test.id,
                                    :ab_test_option_id =>  option.id, 
                                    :value =>              test.base_result)
    end

  end

  # return a hash showing how well the options do
  #
  def self.get_stats(name)
    name = name.to_s.camelize if test_name.is_a?(Symbol)
    AbTest.find_by_name(name).quick_compare
  end

  #----------
  # create / destroy
  #
  #----------


  # In migrations do this:
  #
  #  up:
  #     Abt.create_test(:tweet_in_nav,    9, 0.0, [:red, :blue, :green])
  #  down:
  #     Abt.destroy_test(:tweet_in_nav)
  #

  # Input:
  #   test name     - 
  #   test ordinal  - 
  #   base result   - mostly used to implicitly specify type (ie 0.0 if we want Float)
  #   test_options  - array of possible results 
  #
  # Example
  #    Abt.create_test(:color_test, 1, 0.0, [ :red, :green, :blue ] )
  #
  # Tests are organized into ordinals (specified as an integer), where
  # every test in a given ordinal is guaranteed to be independant of all
  # the other tests in the same ordinal; tests in different ordinals will
  # not have this property; ordinals are offered as an option to work
  # around the problem one sees when running many tests: the most
  # recently created tests will switch options after groups of thousands
  # of users, making it take a long time to collect complete data; put
  # the test in a newer ordinal (preferably after ending all the tests in
  # the older ordinal), and data can be collected more quickly.
  #
  def self.create_test(test_name, ordinal, base_result, test_options, convert_location = "", convert_by_default = true, active = true)

    # Validate test type
    raise "Invalid result type" if !['Integer', 'Fixnum', 'Float', 'BigDecimal'].include?(base_result.class.to_s)

    test_name = test_name.to_s.camelize

    # Determine the spacing to use on this test based on the number of
    # options in each of the tests before this one in the current ordinal
    # (we use the product of the number of options in each previous
    # test); we do this to make sure each test runs independant of all
    # other tests
    tests = AbTest.find(:all, :conditions => ['ordinal = ?', ordinal])
    spacing = tests.map { |t| t.ab_test_options.size }.inject(1) { |n, sum| n * sum } || 1
    # puts "*** test #{test_name} is relatively prime!" if Prime.is_rp?(spacing, test_options.size)

    # Create the test
    test = AbTest.create(:active             => active,
                         :name               => test_name,
                         :ordinal            => ordinal,
                         :spacing            => spacing,
                         :result_type        => base_result.class.to_s,
                         :base_result        => base_result.to_s,
                         :convert_location   => convert_location,
                         :convert_by_default => convert_by_default)

    # Create the options
    test_options.each_with_index do |option, i|
      AbTestOption.create(:ab_test => test, :name => option.to_s.camelize, :ordinal => i + 1)
    end

    return test
  end

  # args:
  #    hh                 - hash of test syms to arrays of option syms
  #    convert_location - we might have some tests that should convert
  #                         after the signup page, and others that
  #                         should convert after checkout. This is a
  #                         string that can be used by the library
  #                         user to find and convert only the right
  #                         tests at the right location.

  #    convert_by_default - should a conversion of all tests
  #
  # it's easy to create a bunch of tests that are orthogonal to each other:
  # just create one after the next, all in the same flight.
  #
  # The problem: if you create 10 tests at once with an average number
  # of options = 4, you get spacing on the last test of 4 ^ 10 =
  # 1,048,576 ...which means that if 1,000 people per day see the test
  # in production it will take FAR too long to gather good data on the
  # last test in the sequence (you'll get 1,000 people getting branch
  # A on day 1...then another 1,000 people getting branch A on day
  # 2...etc.
  #
  # The solution is to break a bunch of today's tests over flights.
  #
  # ...but this is tricky.
  #
  # If we take 10 tests, each with 4 options, and put them in 10 different flights, we get perfect coordination.
  #   customer 1 sees T1-A, T2-A, T3-A ... T10-A
  #   customer 2 sees T1-B, T2-B, T3-B ... T10-B
  # etc.
  # (This is bad bc we're not running 10 seperate tests: we're effectively running one huge test that says
  #    on branch A: make the background color blue and the button large, and...
  #    on branch B: make the background color red  and the button small, and...)
  # so the data we get back is less than perfectly useful.
  #
  # So we've got to pay attention to relative primeness.  If the tests have the following number of options:
  #    T1 -> 3
  #    T2 -> 3
  #    T3 -> 2
  #    T5 -> 9
  #
  # then we can break them up like this:
  #
  #   flight   tests
  #   ---------------
  #    1        T3 (2)
  #    2        T1 (3), T2 (3), T5 (9)
  #
  # bc 2 is relatively prime to 3, and thus 2 is relatively prime to 3x3x9
  # 
  # Our approach here is hardcore, and maybe a bit too strict...but it will work.
  #
  def self.create_multiple_tests(hh, convert_location = "", convert_by_default = true, base_result = 0.0)
    base_flight =  Date.today.days_since_epoch * 10

    verbose = false

    # 'bins' has entries for primes.  If there's a test w 3 options,
    #        another three tests w 7 options, this will get one entry
    #        for bins[3] and one for bins[7]
    #
    bins = {}

    puts "hh:  = #{hh.inspect}" if verbose
    name_to_size = hh.map  { |k, v| [k, v.size]}.to_h
    puts "names_to_size: #{name_to_size.inspect}" if verbose
    size_to_names = name_to_size.safe_invert
    puts "size_to_names: #{size_to_names.inspect}" if verbose

    # 1) deal w tests that have prime # of options -> fill in 'bins'
    #
    puts "STEP 1: primes" if verbose
    size_to_names.select { |opt_size, tests| Prime.prime?(opt_size) }.each do |opt_size, tests| 
      puts " * prime #{opt_size}" if verbose
      bins[opt_size] = tests
    end
    puts "" if verbose

    # 2a) deal w tests w non-prime number of options
    #     * add tests to 'bins'
    #     * note in 'mergeables' which bins should be merged later
    #
    puts "STEP 2A: non-primes" if verbose
    mergeables = []
    size_to_names.select { |opt_size, tests| ! Prime.prime?(opt_size) }.each do |opt_size, tests| 
      mult_bins = Prime.prime_factors(opt_size) 
      puts " * #{tests.inspect} : non-prime #{opt_size}; multiple bins = #{mult_bins.inspect}" if verbose
      mergeables << mult_bins
      # puts " XXX-A #{mult_bins.inspect}"
      # puts " XXX-B #{mult_bins.max}"
      # puts " XXX-C #{tests.inspect}"
      bins[mult_bins.max] = [] if bins[mult_bins.max].nil?
      bins[mult_bins.max] << tests
      # puts " XXX-D #{bins.inspect}"
      bins[mult_bins.max].flatten!
      # puts " XXX-E #{bins.inspect}"
    end

    # 2b) do the merges we flagged earlier
    #
    mergeables.each do |merg|
      target = merg.min
      sources = merg.sort[1,999]
      sources = [target] if merg.size == 1
      puts " * merging from bins #{sources.inspect} to #{target}" if verbose
      sources.each do |src|
        next if src == target  # a weird degenerate case
        bins[target] << bins[src] 
        bins[target].flatten!
        bins[src] = [] 
      end
    end

    # 3) actually create the tests
    #
    bins.keys.sort.each { |key| puts "size #{key} --> tests #{bins[key].inspect}" } if verbose 

    tests = []

    ii = 0
    bins.keys.sort.each do |key|
      flight = base_flight + ii
      ii += 1

      puts "-> #{key} // #{ii}" if verbose
      bins[key].each do |test_name|
        test_options = hh[test_name]
        puts "  ---> #{test_name}" if verbose
        puts "       #{test_options}" if verbose
        tests << create_test(test_name, flight, base_result, test_options, convert_location, convert_by_default, true)
      end

    end

    tests
  end

  # only to be used in migrations ; you actually want to disable tests!
  def self.destroy_test(test_name)
    test_name = test_name.to_s.camelize unless test_name.is_a?(String)

    AbTest.find_by_name(test_name).andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
  end

  #----------
  # List active / enable / disable
  #
  #----------

  def self.all_active()
    AbTest.active
  end

  def self.all_inactive()
    AbTest.inactive
  end

  def self.disable_test(test_name)
    test_name = test_name.to_s.camelize
    AbTest.find_by_name(test_name).update_attributes(:active => false)
  end

  def self.enable_test(test_name)
    test_name = test_name.to_s.camelize
    AbTest.find_by_name(test_name).update_attributes(:active => true)
  end

  def self.add_routes(context, namespace = "admin")
    context.eval( %Q(
    
    # user routes
    # match 'newsletters/index' => "newsletters#index", :as => :newsletter_index   
    # match 'newsletters/:id'   => "newsletters#show",  :as => :newsletter
    
    # admin routes
    namespace '#{namespace}' do
      
      match "ab_tests/add_note/:id"               =>"ab_tests#add_note" , :as => "ab_tests_add_note"
      
      match "ab_tests/active"               =>"ab_tests#active" , :as => "ab_tests_active"
      match "ab_tests/converged"            =>"ab_tests#converged" , :as => "ab_tests_converged"
      resources :ab_tests 
      resources :ab_test_options
      
      
    end # namespace
    
            )) # eval
  end # def


end

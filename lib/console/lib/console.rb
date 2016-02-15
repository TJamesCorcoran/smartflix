class ActiveRecord::Base
  class << self
    TEXT_SEARCH_FIELDS = %w[name]

    # Brackets for easily accessing records by the numbers. Has five modes.
    #
    # Pass a single ID and get a single record back.
    # Example:
    #   Model[1]  #=> #<Model id:1>
    #
    # Pass in a range, and get all the records back with IDs in that range.
    # Example:
    #   Model[1..3]  #=> [#<Model id:1>,#<Model id:3>]
    #
    # Pass in two integers, the first being the starting ID, and the second
    # the length of the array of records to return.
    # Example:
    #   Model[1,2]  #=> [#<Model id:1>,#<Model id:3>]
    #
    # Pass in a string, and get all records back with a name field that
    # matches that string.
    # Example:
    #   Model['atomic robo'] #=> #<Model id:1>
    #
    # Pass in a regexp, and get all records back with a name field that
    # matches that regexp.
    # Example:
    #   Model[/atomic .obo/, :all] #=> [#<Model id:1>]
    def [](arg,length=nil)
      case arg
      when Integer
        if length
          find_by_length(arg,length) 
        else
          find(arg)
        end
      when Range
        find_by_range(arg)
      when String
        raise "#{self} does not have a name field to search" unless search_field
        find(length || :first, :conditions => ["#{search_field} LIKE ?", arg])
      when Regexp
        raise "#{self} does not have a name field to search" unless search_field
        find(length || :first, :conditions => ["#{search_field} REGEXP ?", arg.source])
      end
    end

    # Find the first record for a particular Model, with a bunch of different
    # options.
    #
    # Passing in no arguments yields the first model by id.
    # Example: 
    #   Model.first #=> #<Model id:1>
    #
    # Pass an integer and get back an array of that many objects back.
    # Example:
    #   Model.first(2) #=> [#<Model id:1>,#<Model id:2>]
    #
    # Pass a hash or string and get the first match back, as if the
    # argument had been passed to :conditions in a typical find.
    # Examples:
    #   Model.first(:foo => 'bar') #=> #<Model id:3>
    #   Model.first("foo == 'bar'") #=> #<Model id:3>
    #
    # Pass a regular expression and get back the first record which matches
    # the regular expression in the specific full text search field.
    # Example:
    #   Model.first(/bar/) #=> #<Model name:"bar">
    #
    # Pass in an integer followed by any of the above and get back multiple
    # matches.
    # Examples:
    #   Model.first(2, :foo => 'bar') #=> [#<Model id:1>,#<Model id:3>]
    #   Model.first(2, /bar/) #=> [#<Model name:"bar">,#<Model name:"barber">]
    def first(*args)
      find_first_or_last(:first, *args)
    end

    # Find the last record for a particular Model, with a bunch of different
    # options.
    #
    # See the documentation for :first.  :last has all of the same options.
    def last(*args)
      find_first_or_last(:last, *args)
    end
    
    # Find all records for a particular Model with or without particular
    # conditions.
    #
    # Example:
    #   Model.all #=> [#<Model id:1>,#<Model id:2>]
    # Example:
    #   Model.all(:foo => 'bar') #=> [#<Model id:2>]
    def all(arg={})
      find(:all, :conditions => arg)
    end

    private

    def find_by_range(range)
      find(:all, 
           :conditions => %Q[ #{primary_key} >= #{range.begin} AND 
                              #{primary_key} <= #{range.end} ])
    end

    def find_by_length(start,length)
      find(:all, 
           :conditions => "#{primary_key} >= #{start}",
           :limit => length,
           :order => primary_key )
    end

    def find_with_regex(regex,quant=nil,order=nil)
      raise "#{self} does not have a name field to search" unless search_field
      if quant.nil?
        find(:first, :conditions => ["#{search_field} REGEXP ?", regex.source], :order => order)
      else
        find(:all, :conditions => ["#{search_field} REGEXP ?", regex.source], :limit => quant, :order => order)
      end
    end

    def find_first_or_last(orientation, *args)
      order = orientation == :last ? "#{primary_key} DESC" : nil
      q = args.first.is_a?(Integer) ? args.shift : nil
      case args.first
      when nil
        q ? find(:all, :limit => q, :order => order) : find(:first, :order => order)
      when String,Hash
        q ? 
          find(:all, :conditions => args.first, :limit => q, :order => order) : 
          find(:first, :conditions => args.first, :order => order)
      when Regexp
        find_with_regex(args.first,q,order)
      end
    end

    def search_field
      @search_field ||= TEXT_SEARCH_FIELDS.detect { |s| self.column_names.include?(s) }
    end
  end
end

# Utility method to use if MySQL connection dies for the console
def recon
  !!ActiveRecord::Base.establish_connection
end

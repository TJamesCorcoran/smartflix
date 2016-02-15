# Class to manage options by which products can be sorted, not database backed

# Define a custom exception
class InvalidSortOption < StandardError
end

class ProductSortOption


  attr_accessor :name
  attr_accessor :value

  # Constructor takes nil (assign default), a hash with :name and / or
  # :value defined, or a name and value as two arguments
  def initialize(*args)
    if (args.size == 1 && args[0].is_a?(Hash))
      options = args[0]
      @name = options[:name]
      @value = options[:value]
    elsif (args.size == 1 && args[0].nil?)
      # Use the first of the valid sort options as the default
      @name = @@sort_options[0].name
      @value = @@sort_options[0].value
    elsif (args.size == 2)
      @name, @value = args
    else
      raise InvalidSortOption, "Invalid arguments provided to ProductSortOption constructor"
    end

  end

  @@sort_options = []
  @@sort_options << ProductSortOption.new('User Rating', 'toprated')
  @@sort_options << ProductSortOption.new('Title', 'title')
  @@sort_options << ProductSortOption.new('Newest First', 'newest')
  @@sort_options << ProductSortOption.new('Oldest First', 'oldest')

  def ProductSortOption.sort_options
    @@sort_options
  end

end

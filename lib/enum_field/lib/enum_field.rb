module EnumField
  def enum_field(field_name, *constants)
    # Create a module that is the capitalized field name to hold the constants, set up the constants
    namespace = Module.new
    const_set(field_name.to_s.upcase, namespace)
    constants.each_with_index do |entry, index|
      namespace.const_set(entry[:constant], index + 1)
      # While we're here, define a simple method to ask if this field has some value
      define_method("#{entry[:constant].to_s.downcase}?") { self.send(field_name) == index + 1 }
    end
    # Create basic lookup methods specified
    keys = constants.map(&:keys).flatten.uniq
    keys.each do |key|
      define_method("#{field_name.to_s}_#{key.to_s}") { constants[self.send(field_name).to_i - 1][key] }
    end
    # Class methods
    metaclass = class << self ; self ; end
    # Add a method to get a list of the allowed values
    metaclass.send(:define_method, "#{field_name.to_s}_values") { (1..constants.size).to_a }
    # Create methods to list all the lookups available, useful for select dropdowns in forms
    keys.each do |key|
      metaclass.send(:define_method, "#{field_name.to_s}_#{key.to_s.pluralize}") do
        results = []
        constants.each_with_index { |entry, index| results << [entry[key], index + 1] }
        results
      end
    end
  end
end

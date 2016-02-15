class Object

  # what can this object do that not all objects can do?
  def uniq_methods
    self.methods - Object.methods
  end

  def in?(*args)
    args.include?(self) || args.any? do |arg|
      (arg.respond_to?(:include?) && arg.include?(self)) || ((arg.is_a?(Array) || arg.is_a?(Hash) || arg.is_a?(Set)) && self.in?(*arg))
    end
  end
  
  def to_array
    Array(self)
  end

  def to_bool
    ! (self == false || self == nil)
  end
  
  def false_to_nil
    self || nil
  end

# http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
  def meta_def name, &blk
    (class << self; self; end).instance_eval { define_method name, &blk }
  end

  # XYZ's own extension to Jay Fields' idea
  # We use this in cases like
  #     app/models/newsletter.rb
  # which has a line
  #     include NewsletterEditor::Model::Newsletter
  # which includes
  #     vendor/plugins/newsletter_editor/lib/newsletter_editor/model.rb
  #
  # ...which means that we want to extend some ** OTHER ** class with 
  # a class_method
  #
  def meta_def_other cl, name, &blk
    (class << cl; self; end).instance_eval { define_method name, &blk }
  end

  # On class User, return "User"
  # On class UserPhoneNumber return "User Phone Number"
  #
  def name_pretty
    to_s.underscore.split("_").map(&:capitalize).join(" ")
  end
end

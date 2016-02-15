Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file|  require file }
ActiveRecord::Base.send(:extend, EnumField)

# This file contains various patches and hacks necessary to make our subdomain 
#  infrastructure work so awesomely.


# Monkey patch - 
#  We're modifying the Mapper#connect method to make it add additional routes for specific routes.
#  Mapper#connect_subdomains_to must be called first, in order for this to work.  It checks if the
#  current route has a :controller option pointing to the value set by connect_subdomains_to( value ).
#  If true, it then takes the @subdomains array and iterates over it, adding a corresponding route
#  for each of them.
ActionController::Routing::RouteSet::Mapper.class_eval do
  alias :real_connect :connect
  
  def connect(path, options = {})
    real_connect(path, options)

    @subdomains.each do |subdomain,controllers|
      if controllers.include?(options[:controller])
        @set.add_route(path, options.merge( :controller => "subdomain/#{subdomain}/#{options[:controller]}", 
                                            :conditions => { :subdomain => subdomain } ))
      end
    end
    
  end
end


# Routing Mapper extensions
module Subdomain
  module Routing
    module DSL
      module MapperExtensions
        
        # Extension which defines two instance variables which enable the monkey-patched connect
        #  method to connect specific routes to subdomains. 
        # Creates a data structure in @subdomains which looks like the following:
        #   @subdomains = { "mbp"         => ['controller1', 'controller2', 'controller3']
        #                   "woodturning" => ['controller1'] }
        #
        # A hash of subdomain names, each referring to an array of controllers which they are 
        #  prepared to accept requests for.
        def connect_subdomains
          @subdomains = {}
          Dir.new("#{Rails.root}/app/controllers/subdomain").each do |entry|
            sd_match = /^[a-z]+$/.match(entry)
            next unless sd_match
            
            @subdomains[sd_match[0]] = Dir.new("#{Rails.root}/app/controllers/subdomain/#{sd_match[0]}").map do |sub_entry|
              cont_match = /^([a-z]+)_controller\.rb$/.match(sub_entry)
              next unless cont_match
              
              cont_match[1]
            end.compact
          end
        end
        
      end
    end
  end
end
ActionController::Routing::RouteSet::Mapper.send :include, Subdomain::Routing::DSL::MapperExtensions


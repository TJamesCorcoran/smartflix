Dir[File.dirname(__FILE__) + '/app/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
ActionController::Base.send(:include, TrackOrigin)


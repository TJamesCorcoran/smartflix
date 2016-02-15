Dir[File.dirname(__FILE__) + '/app/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/app/controllers/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

# controllers to load later
#
Rails.application.config.autoload_paths += [ ( File.dirname(__FILE__) + '/app/controllers' ) ]


view_path = File.join(File.dirname(__FILE__) + '/app/views')
if File.exist?(view_path)
  ActionController::Base.view_paths.insert(1, view_path) 
end



# newsletter
#

Dir[File.dirname(__FILE__) + '/app/models/*.rb'].each {|file|  require file }
Dir[File.dirname(__FILE__) + '/app/controllers/*.rb'].each {|file|  require file }
Dir[File.dirname(__FILE__) + '/app/controllers/admin/*.rb'].each {|file|  require file }
Dir[File.dirname(__FILE__) + '/app/helpers/*.rb'].each {|file|  require file }
Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file|  require file }
Dir[File.dirname(__FILE__) + '/app/mailers/*.rb'].each {|file|  require file }


view_path = File.join(File.dirname(__FILE__) + '/app/views')
if File.exist?(view_path)
  ActionController::Base.view_paths.insert(1, view_path) # push it just underneath the app
end


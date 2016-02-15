require File.dirname(__FILE__) + '/lib/acts_as_auto_admin_controller'


view_path = File.join(File.dirname(__FILE__) + '/app/views')
if File.exist?(view_path)
  ActionController::Base.view_paths.insert(1, view_path) # push it just underneath the app
end


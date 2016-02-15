# extend ActiveRecord to give it access to session
require 'basichacks/activerecordhack'

# load models
#------------ 
# this is simple, but it does not work
#     Dir[File.dirname(__FILE__) + '/app/models/*.rb'].each {|file|  require file }
# do it the long way; order MATTERS!
require  File.dirname(__FILE__) +  '/app/models/ab_test_stats'
require  File.dirname(__FILE__) +  '/app/models/ab_test_option'
require  File.dirname(__FILE__) +  '/app/models/ab_test_result'
require  File.dirname(__FILE__) +  '/app/models/ab_test_result_reference'
require  File.dirname(__FILE__) +  '/app/models/ab_test_visitor'
require  File.dirname(__FILE__) +  '/app/models/ab_test'

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file|  require file }

Dir[File.dirname(__FILE__) + '/app/controllers/*.rb'].each {|file|  require file }
Dir[File.dirname(__FILE__) + '/app/controllers/admin/*.rb'].each {|file|  require file }

view_path = File.join(File.dirname(__FILE__) + '/app/views')
if File.exist?(view_path)
  ActionController::Base.view_paths.insert(1, view_path) 
end


# config.autoload_paths += %W(#{config.root}/lib)

ActionController::Base.send( :include, Abt)
ActionView::Base.send(       :include, Abt)
ActiveRecord::Base.send(     :include, Abt)
ActionMailer::Base.send(     :include, Abt)



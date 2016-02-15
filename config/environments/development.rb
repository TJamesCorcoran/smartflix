SmartFlix::Application.configure do

  config.middleware.use ExceptionNotifier,
  :email_prefix => "[SF-DEVEL] ",
  :sender_address => %{"Exception Notifier" <none@smartflix.com>},
  :exception_recipients => %w{xyz@xyz.com}

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :stderr

  #----------
  # errors
  #----------
  config.consider_all_requests_local       = true
  config.whiny_nils = true

  #----------
  # cache
  #----------
  
  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  # for devel, use the memory store - 1 cache per process (script/server )

  config.action_controller.perform_caching   = false  
  config.cache_store = :file_store, "fragment_cache"
  config.cache_classes                       = false
  config.action_view.cache_template_loading  = false


  
  #----------
  #  debugging
  #----------
  

  
  #----------
  # server locations
  #----------
  
  WEB_SERVER = "localhost:3000"
  
  #----------
  # email
  #----------
  
  config.action_mailer.raise_delivery_errors = true # lets see errors!
  
end

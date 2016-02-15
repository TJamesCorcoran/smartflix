# SMARTFLIX
#

#----------
# server locations
#----------
WEB_SERVER = 'smartflix.com'
BASE_SERVER = 'sf-internal'

SmartFlix::Application.configure do

  config.middleware.use ExceptionNotifier,
  :email_prefix => "[SF] ",
  :sender_address => %{"Exception Notifier" <none@smartflix.com>},
  :exception_recipients => %w{xyz@smartflix.com}


  #----------
  # errors
  #----------
  config.consider_all_requests_local       = false


  #----------
  # cache
  #----------

  config.action_controller.perform_caching = true
  config.cache_classes = true

  #----------
  # asset pipeline
  #----------

  config.serve_static_assets = false # let nginx serve static files

  config.assets.compile      = true  # true = on-demand live compile / false = precompile
  config.assets.compress     = true
  config.assets.digest       = true
  config.assets.enabled      = true 

  # config.assets.manifest = YOUR_PATH
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx
  # config.action_controller.asset_host = "http://assets.example.com"
  config.assets.precompile += %w( univ_store.css admin_all.css )

  #----------
  # ssl
  #----------
  
  config.force_ssl = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true


  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :log

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  #----------
  # email
  #----------

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => WEB_SERVER }

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

end

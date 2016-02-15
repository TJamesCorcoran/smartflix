#--------------
# Smartflix.com
#--------------

require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  # Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  Bundler.require(:default, :assets, Rails.env)
end

module SmartFlix
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.action_view.javascript_expansions[:defaults] = %w(jquery jrails)
    
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
    
    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    
    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true
    
    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql
    
    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true
    
    # Enable the asset pipeline
    config.assets.enabled = true
    
    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    
    #----------
    # Location of password file for admin access http authentication
    # To create this file, do /usr/sbin/htpasswd2 -c admin-auth-htpasswd udadmin
    #----------
    
    SF_AUTH_ADMIN       = { :user => "rcadmin",          :pwd => "XXX" }
    SF_AUTH_NEWSLETTER  = { :user => "NewsletterEditor", :pwd => "XXX" }
    
    
    SF_AUTH_FILE_ADMIN      = "#{Rails.root}/config/admin-auth-htpasswd"
    SF_AUTH_FILE_NEWSLETTER = "#{Rails.root}/config/newsletter-auth-htpasswd"
    
    require "socket"
    CURRENT_HOSTNAME = Socket.gethostname
    
    if ( Rails.env == 'production')
      WEB_HOST     = "XXX"
      WEB_PORT     = 80
      BACKEND_HOST = "XXX"
      BACKEND_HOST_FOR_URL = "XXX"
      BACKEND_PORT = 80
    else
      WEB_HOST     = "XXX"
      WEB_PORT     = 3010
      BACKEND_HOST = "XXX"
      BACKEND_HOST_FOR_URL = "XXX"
      BACKEND_PORT = 3000
    end
    
    BACKEND_URL = "#{BACKEND_HOST_FOR_URL}:#{BACKEND_PORT}"
    WEB_URL     = "#{WEB_HOST}:#{WEB_PORT}"
    
    
    web = backend = false
    
    
    if ENV['FORCE_WEB']
      web = true
    elsif ENV['FORCE_BACKEND']
      backend = true
    elsif CURRENT_HOSTNAME == WEB_HOST
      web = true
    elsif CURRENT_HOSTNAME == BACKEND_HOST
      backend = true
    end
    
    if web
      #  puts "******************** WEB" unless  (Rails.env == 'test')
      ON_WEB       = true
      ON_BACKEND   = false
    else
      #  puts "******************** BACKEND" unless  (Rails.env == 'test')
      ON_WEB       = false
      ON_BACKEND   = true
    end
    
    
    #----------
    # email addrs
    #----------
    
    # full email addrs depends on plugins/basichacks/lib/actionmailerhack.rb
    
    EMAIL_FROM          = 'SmartFlix <outgoing@smartflix.com>'
    EMAIL_FROM_SUPPORT  = 'SmartFlix <info@smartflix.com>'
    EMAIL_FROM_AUTO     = 'SmartFlix <autorun@smartflix.com>'
    EMAIL_FROM_JOBS     = 'SmartFlix <jobs@smartflix.com>'
    EMAIL_FROM_BUGS     = 'outgoing@smartflix.com'  # don't put in full name; exception notifier chokes despite actionmailerback
    
    require 'etc'
    EMAIL_TO_DEFAULT    = 'xyz@smartflix.com'
    EMAIL_TO_BUGS       = 'xyz@smartflix.com'
    EMAIL_TO_DEVELOPER  = "#{Etc.getlogin}@smartflix.com"
    EMAIL_TO_BOUNCES    = 'bounces@smartflix.com'
    EMAIL_TO_BADDATA    = 'xyz@smartflix.com'
    
    SF_ONEPAGE_AUTH_KEY = 'Du25mOf8louK5Bbs'
    SESSION_TIMEOUT = 1800
    
    # in devel we can log into any customer's account w a fake password 
    FAKE_DEVEL_PASSWORD = "DEVEL"
    
    BACKEND_VIDCAP_LOCATION      = "#{Rails.root}/../../shared/vidcaps"
    BACKEND_BLOG_IMAGES_LOCATION = "#{Rails.root}/../../www/archive"
    BACKEND_PRINTER_NAME         =  "laserjet2420_sf"
    
    # CC encryption
    #
    CC_ENCRYPT_KEY_FILENAME = "sf_encrypt_key.pem"
    CC_DECRYPT_KEY_FILENAME = "sf_decrypt_key.pem"
    
    
    if Rails.env.production?
      EMAIL_TO_PURCHASING                        = 'purchasing@smartflix.com'
      VIDCAP_WEB_BASE                            = '/vidcaps'
      VIDCAP_LOCAL_BASE                          = '/home/smart/rails/sfw/vidcaps'
      
      # updated 29 Dec 2014 for XXX
      #
      AUTHORIZE_NET_API_LOGIN_ID                   = 'XXX'
      AUTHORIZE_NET_TRANSACTION_KEY                = 'XXX'
      ActiveMerchant::Billing::Base.gateway_mode = :production
    else
      EMAIL_TO_PURCHASING                        = '#{ENV["USER"]}_purchasing@smartflix.com'
      VIDCAP_LOCAL_BASE                          = "#{Rails.root}/public/catalog/vidcaps/sfw"
      VIDCAP_WEB_BASE                            = '/vidcaps'
      ActiveMerchant::Billing::Base.gateway_mode = :test
      
      # updated 29 Dec 2014 for Bad Corgi Inc.
      #
      AUTHORIZE_NET_API_LOGIN_ID                   = 'XXX'
      AUTHORIZE_NET_TRANSACTION_KEY                = 'XXX'
    end

    
    
    SF_OBFUSCATED_CONTACT_EMAIL           = "<script type=\"text/javascript\">  document.write('in' + 'fo' + '@' + 'smart' + 'flix' + '.com<br>'); </script>"
    SF_MAILING_ADDRESS_HTML = 'XXX<br>7 Central St.<br>Suite 140<br>Arlington MA 02476'
    
    APPLICATION_NAME = "sfw"
    SITE_NAME        = 'SmartFlix'
    SITE_ABBREV      = 'SF'
    # # Wiki configuration
    # Wiki.configure do |config|
    #   config.layout = 'store'
    #   config.current_user = :current_customer
    #   config.user_is_wiki_editor = lambda { |customer|   customer.andand.wiki_editor?  }
    #   config.default_redirect = :wiki_default_redirect
    #   # Specify that each wiki page can be associated with up to 2 categories
    
    # # XYZFIX P2 - get this working again!  config.model_associations = [:category, :category]
    #   config.model_associations = []
    
    #   config.custom_link_helpers = {
    #     :video => :wiki_video_link,
    #     :category => :wiki_category_link,
    #     :inline => :wiki_inline,
    #     :sidebar => :wiki_sidebar
    #   }
    
    # end
    # WikiPage.finish_initialization
    # WikiPagesController.finish_initialization
    
    
    
    # test w
    #    SfMailer.simple_message("xyz@smartflix.com", "outgoing@smartflix.com", "subj" , "body")
    
    # ActionMailer::Base.smtp_settings = {
    #   :address              => "XX.XX.XX.XX",
    #   :port                 => XX,
    #   :domain               => "smartflix.com",
    #   :authentication       => :plain,  # :plain // :login // :cram_md5
    #   :user_name            => "outgoing@smartflix.com",
    #   :password             => "XXX",
    #   :tls                  => true,
    #   :ssl                  => true,
    #   :enable_starttls_auto => true
    # }
    
    config.action_mailer.smtp_settings = {
      :address              => "XX.XX.XX.XX",
      :port                 => XX,
      :domain               => "smartflix.com",
      :authentication       => :plain,  # :plain // :login // :cram_md5
      :user_name            => "outgoing@smartflix.com",
      :password             => "XXX",
      :tls                  => true,
      :ssl                  => true,
      :enable_starttls_auto => true
    }


    FIRST_MONTH_FREE  = true
    UNIV_VIEW_FOR_ALL = false   # THIS IS A MONEY LOSER!
    
    #----------
    # delay
    #----------
    
    # thus we do stuff like
    #    Mailer.delay.deliver_message(to, from, subj, body)
    #           ^^^^^
    # in devel we don't always need the complexity, and we might prefer the immediate feedback
    # of getting mail ASAP.
    #
    # ...so monkeypatch delay() to return self ...which is the same as short circuiting it.
    #
    
    USE_DELAY_IN_DEVEL = false
    
    unless ( (Rails.env == 'production')  || USE_DELAY_IN_DEVEL  )
      
      #  docs say that this should work, but it doesn't!
      # 
      #  Delayed::Worker.delay_jobs = false
      
      # rails 2 approach:
      # -------------------
      # 
      #   module UndoDelay
      #     def delay(options = {}) 
      #       puts "method delay() is a pass-through"
      #       self 
      #     end
      #   end
      #   require 'delayed_job'
      #   Object.send(:include, UndoDelay)   
      
      
      # rails 3 approach:
      # -------------------
      module Delayed
        module DelayMail
          # create a new delay() method that does nothing but return self
          # note that the delay gem already mixes in Delayed::DelayMail
          def delay(options = {})
            self
          end
        end
      end 
    end # delay stuff



  end
end

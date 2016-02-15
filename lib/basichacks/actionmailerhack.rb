module ActionMailer
  class Base
    def perform_delivery_smtp(mail)
      destinations = mail.destinations
      mail.ready_to_send

      # ?? ?? 2009
      #------------
      # allow us to use names in email addrs, like
      #     "xxx xxx <xyz@smartflix.com>"
      #
      # http://www.hostingrails.com/Cannot-specify-sender-name-using-SMTP
      
      sender = (mail['return-path'] && mail['return-path'].spec) || Array(mail.from).first
      
      smtp = Net::SMTP.new(smtp_settings[:address], smtp_settings[:port])
      
      # 14 Mar 2012
      #-------------
      # we're starting to use a new mail server
      # and it demands SSL / TLS
      #
      # rails 2.3.5 fails the test
      #
      # https://rails.lighthouseapp.com/projects/8994/tickets/1731-make-enable_starttls_auto-opt-in-in-actionmailer#ticket-1731-18
      #
      
      if smtp_settings[:ssl]
        smtp.enable_tls()
      else
        smtp.enable_starttls_auto if smtp_settings[:enable_starttls_auto] && smtp.respond_to?(:enable_starttls_auto)
      end
      
      
      
      
      smtp.start(smtp_settings[:domain], smtp_settings[:user_name], smtp_settings[:password],
                 smtp_settings[:authentication]) do |smtp|
        smtp.sendmail(mail.encoded, sender, destinations)
      end
    end
  end
end
  


module ActionMailerHack

  module ClassMethods
    def view_paths
      @view_paths ||= [template_root]
    end
    
    def view_paths=(value)
      @view_paths = value
    end
    
    def prepend_view_path(path)
      view_paths.unshift(*path)
    end
    
    def append_view_path(path)
      view_paths.push(*path)
      if defined?(ActionView::TemplateFinder)
        ActionView::TemplateFinder.process_view_paths(path)
      end
    end
  end
  
  module InstanceMethods
    def view_paths
      self.class.view_paths
    end
    
    def initialize_template_class_with_view_paths(assigns)
      ActionView::Base.new(view_paths, assigns, self)
    end
    
    def template_path_with_view_paths
      "{#{view_paths.join(',')}}/#{mailer_name}"
    end
  end
  
  private
  
  def self.included(mailer)
    mailer.send :include, InstanceMethods
    mailer.send :extend, ClassMethods
    
    mailer.alias_method_chain :initialize_template_class, :view_paths
    mailer.alias_method_chain :template_path, :view_paths
  end
end

ActionMailer::Base.send :include, ActionMailerHack

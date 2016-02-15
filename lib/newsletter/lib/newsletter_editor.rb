require 'ostruct'

class NewsletterEditor
  PLUGIN_ROOT = File.join(File.dirname(__FILE__), '..')
  
  DefaultConfiguration = {
    :template_path => File.join(Rails.root, 'lib', 'newsletter_templates.yaml')
  }
  
  
  # class method that returns an hash of all templates:
  #
  #   { "Header" => <NewsletterEditor::Template>, 
  #     "Footer" => <NewsletterEditor::Template>, 
  #     "Basic Block" => <NewsletterEditor::Template>, 
  #     ...
  #   }
  #
  # This is used thusly:
  #
  #    @newsletter = ...
  #    @newsletter.sections.each do |ss|
  #       NewsletterEditor.templates[ss.section].process(ss,...)
  #    end
  #
  # What this does is 
  #    1) fetch a PARTICULAR newsletter
  #    2) for each (instantiated, actual) SECTION in that newsletter
  #    3) ...find the TEMPLATE w a matching section name and call the process() method
  #    4) ...feeding it the DATA from the instantiated actual newsletter section
  #
  def self.templates(reload=false)
    
    if reload || Rails.env != 'production'
      # reload every time in devel
      @templates = YAML.load_file(config[:template_path]).inject({}) { |o,(n,d)|
        
        verbose_parse = false
        if verbose_parse
          puts "----------" 
          puts "*** o = #{o.inspect}" 
          puts "*** n = #{n.inspect}" 
          puts "*** d = #{d["html"].inspect}"
        end
        if d["html"].match(/(INCLUDE_TEMPLATE: *([a-zA-Z ]+)!)/)
          if verbose_parse
            puts "*** INC = #{$1}" 
            puts "*** INC = #{$2}"
            puts "*** o[#{$2}].html = #{o[$2].html}"
          end
          raise "template '#{$2}' does not exist, unable to INCLUDE" if o[$2].nil?
          d["html"].gsub!($1, o[$2].html) 
          if verbose_parse
            puts "*** INC >> #{d.inspect}" 
          end
        end
        o[n] = Template.new(d); o 
      }
    else
      # only load once in production
      @templates ||= YAML.load_file(config[:template_path]).inject({}) { |o,(n,d)| o[n] = Template.new(d); o }
    end
  end
  
  def self.user_templates
    templates.reject { |n,t| t.hide }
  end
  
  def self.config(conf=nil)
    return @configuration || DefaultConfiguration unless conf
    @configuration = DefaultConfiguration.merge(conf)
  end
  
  def self.add_routes(context, namespace = "admin")
    context.eval( %Q(
    
    # user routes
    match 'newsletters/index' => "newsletters#index", :as => :newsletter_index   
    match 'newsletters/:id'   => "newsletters#show",  :as => :newsletter
    
    # admin routes
    namespace '#{namespace}' do
      resources :newsletters do
        collection do
          get :section
        end
    
        member do 
          get  :preview 
          get  :nl_status 
          post :section 
          post :deliver 
          post :kill 
          post :preview_email 
        end # member
      end # resources
    end # namespace
    
            )) # eval
  end # def
  
end

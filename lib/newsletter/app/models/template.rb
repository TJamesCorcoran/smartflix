class NewsletterEditor

  #  An instance of this class represents one particular template.
  #
  #  Created like this:
  #      NewsletterEditor.templates['Header']
  #  
  #  Once a template is created, the method .process() is called on it to generate HTML
  #
  class Template
    def initialize(data)
      @fields = data['fields']
      @html = data['html']
      @hide = data['hide']
    end

    attr_reader :fields, :html, :hide

    # this method generates HTML
    #
    # inputs:
    #    section    - ??
    #    customer   - customer for whom it's aimed
    #    other_vars - hash
    #
    def process(section = nil, customer = nil, other_vars = {})
      
      # 1) create a view to do the rendering
      #
      view = ActionView::Base.new(ActionController::Base.view_paths, {})  
      class << view  
        include Rails.application.routes.url_helpers    # for application routes helpers

        include EmailHelper
        include ApplicationHelper
        include ActionDispatch::Http::URL
      end  

      # 2) set up the local locals we want in the rendering
      #     i)   
      #     ii) 
      locals = section ? section.fields.map { |f| [f.field, f.data] } : []
      locals << [:customer,customer]
      other_vars.each { |k,v| locals << [k,v] }
      locals = locals.to_hash
      # make sure keys are SYMBOLS, bc that's what a template wants in its 'locals' arguments
      locals = locals.map { |k,v| [ k.to_sym, v ]}.to_hash
      puts "====="
      puts "locals =  #{locals.inspect}"

      # 3) render the template section (the HTML from the template yaml file)
      #
      
      puts "html = #{@html}" 
      ret = view.render(:inline => @html, :locals => locals).html_safe
      puts "ret 1 = #{ret}" 

      # 4) do CSS post processing
      #     (XYZ tweaks of 26 Sep 2011)
      if md = ret.match(/<newsletter_style\s+(\w+)\s+["'](.*)["']\s?>/)
        tag = $1
        style = $2
        ret.gsub!(md[0],"")
        ret.gsub!("<#{tag}", "<#{tag} style='#{style}' ")
      end

      puts "ret 2 = #{ret}" 

      # 5) return it
      #
      ret.html_safe
    end
  end
end


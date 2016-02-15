class Button < ActionView::Base
  
  DEFAULT_OPTIONS = { :type     => :standard, 
                      :method   => :get, 
                      :ajax     => false, 
                      :size     => :small, 

                      # :float    => nil, 
                      # :display    => nil, 

                      # :confirm  => nil, 
                      # :width    => nil, 
                      # :align    => nil, 
                      # :onclick  => nil,
                      # :content  => nil,
                      # :url      => nil,
                      # :class    => nil
  }


  def initialize(content,*args)
    @options = args.last.is_a?(Hash) ? args.pop : {}
    @options.assert_valid_keys(:type, :method, :ajax, :size, :float, :confirm, :width, :align, :onclick, :url, :value, :name, :class, :disabled, :host, :display)

    @options.merge!( :content => content )
    @options = DEFAULT_OPTIONS.merge( @options )
    process_options!

    to_s
  end
  private

  def process_options!
    @options[:styles] = { :width => @options[:width] ? "#{@options[:width]}px" : nil,
                          :float => @options[:float],
                          :text_align => @options[:align] }.to_styles

    classes = [ @options[:type].to_s,
                @options[:size].to_s,
                @options[:rss].to_s,
                @options[:method] == :get ? 'button' : nil ]
    classes = classes.uniq.reject(&:blank?).sort
    classes << classes.join('_')
    classes << @options[:class]

    @options[:classes] = classes.uniq.join(' ')

    @options[:disabled] = @options[:type] == :inactive ? 'disabled' : nil
  end


  def button_path_for(type)
    raise InvalidType unless valid_type?(type)

    "#{button_path(:web)}/#{type.to_s}"
  end

  def size_prefix_for(size)
    sizes = { 'tiny' => 't', 'small' => 's', 'large' => 'l' }
    sizes[ size.to_s.downcase ]
  end

  def button_path(side)
    case side
      when :web
        '/images/buttons'
      when :local
        "#{RAILS_ROOT}/public/images/buttons"
    end
  end

  def valid_type?(type)
    File.exist?( "#{button_path(:local)}/#{type}" )
  end

  def protect_against_forgery?; false; end

public

  #----------
  # graphic output (just the button - no form !)
  #----------
  
  # options:
  #   * confirm
  #   * onclick
  #   * type
  def button_image
    raise 'Invalid option, only one of :confirm or :onclick allowed' if @options[:confirm] && @options[:onclick]

    if @options[:confirm]
      @options[:onclick] = "return confirm('#{@options[:confirm]}');" 
      @options.delete(:confirm)
    end



    content_tag("button",
                 content_tag('span',@options[:content]),
                :type => 'submit',
                :onclick => @options[:onclick],
                :class => @options[:classes],
                :disabled => @options[:disabled],
                :style => @options[:styles],
                :value => @options[:value],
                :name => @options[:name] )
  end

  def button_submit
    raise 'Invalid option, only one of :confirm or :onclick allowed' if @options[:confirm] && @options[:onclick]

    if @options[:confirm]
      @options[:onclick] = "return confirm('#{@options[:confirm]}');" 
      @options.delete(:confirm)
    end

    content_tag("button",
                 content_tag('span',@options[:content]),
                :type => 'submit',
                :onclick => @options[:onclick],
                :class => @options[:classes],
                :disabled => @options[:disabled],
                :style => @options[:styles],
                :value => @options[:value],
                :name => @options[:name] )
  end


  #----------
  # REST / HTML action methods - low level
  #----------

  # Not actually a get currently, this is intentional
  def ajax_get
    form_tag(@options[:url], :class => 'button_form', :remote =>true) + 
      button_image + 
    "</form>".html_safe
  end

  def standard_get
    real_method = "GET"
    form_tag(@options[:url], :class => 'button_form') + 
      (real_method ? hidden_field_tag('_method', real_method.to_s.upcase) : '') +
      button_image + 
    "</form>".html_safe
  end


  def standard_post(real_method=nil)
    form_tag(@options[:url], :class => 'button_form') + 
      (real_method ? hidden_field_tag('_method', real_method.to_s.upcase) : '') +
      button_image + 
    "</form>".html_safe
  end

  def ajax_post(real_method=nil)
    form_remote_tag(:url => @options[:url], :class => 'button_form') + 
      (real_method ? hidden_field_tag('_method', real_method) : '') +
      button_image + 
    "</form>".html_safe
  end

  def anchor
    if @options[:host]
      link_to( content_tag(:span, @options[:content], :style => inline_button_text_style),
              @options[:url].to_s, :style => inline_button_style)
    else
      link_to content_tag(:span, @options[:content]), 
              @options[:url].to_s, 
              :class => @options[:classes], 
              :onclick => @options[:onclick],
              :confirm => @options[:confirm],
              :style => @options[:styles]
    end
  end

  #----------
  # REST / HTML action methods - med level
  #----------


  def get
    @options[:ajax] ? ajax_get : anchor # standard_get
  end

  def post
    @options[:ajax] ? ajax_post : standard_post
  end
  
  def put
    @options[:ajax] ? ajax_post('put') : standard_post('put')
  end

  def delete
    @options[:ajax] ? ajax_post('delete') : standard_post('delete')
  end

  def font_size_for(size)
    sizes = { 'tiny' => 10, 'small' => 11, 'large' => 13 }
    sizes[ size.to_s.downcase ]
  end

  def line_height_for(size)
    sizes = { 'tiny' => 12, 'small' => 17, 'large' => 31 }
    sizes[ size.to_s.downcase ]
  end

  def height_for(size)
    sizes = { 'tiny' => 17, 'small' => 26, 'large' => 37 }
    sizes[ size.to_s.downcase ]
  end

  def inline_button_style
    width = @options[:width] ? "#{@options[:width].to_i}px" : "115px"
    style = "display: block;"
    style << "text-align: center;"
    style << "text-decoration: none;"
    style << "width: #{width};"
    dir = button_path_for(@options[:type])
    size = size_prefix_for(@options[:size])
    style << "background: transparent url(http://#{@options[:host]}#{dir}/#{size}b.gif) repeat-x scroll left top;"
    style << "height: #{height_for(@options[:size])}px;"
  end

  def inline_button_text_style
    style = "font-family: Verdana,Arial,Helvetica,sans-serif;"
    style << "font-size: #{font_size_for(@options[:size])}px;"
    style << "font-weight: bold;"
    style << "line-height: #{line_height_for(@options[:size])}px;"
    style << "color: white;"
  end

  def to_s
    case @options[:method].to_sym
      when :get  then get
      when :post then        post
      when :put  then         put
      when :delete then      delete
      when :submit then      button_submit
      when :none then        button_image
    end
  end


end


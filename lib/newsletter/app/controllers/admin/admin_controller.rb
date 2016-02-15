class NewsletterEditor
  module AdminController

    #----------
    # admin facing
    #----------
    def index
      options = params[:full] ? { :order => 'created_at DESC' } : { :order => 'created_at DESC', :limit => 10 }
      @newsletters = Newsletter.find(:all, options)
    end
    
    def show
      @admin = true
      @newsletter = Newsletter.find(params[:id])
    end


    def new
      @newsletter = nil
      begin
        @newsletter = Newsletter.create!(:headline => "")
        @campaign = Campaign.create!(:name => "newsletter #{@newsletter.id}", 
                                     :ct_code => "nl#{@newsletter.id}",
                                     :fixed_cost => defined?(NEWSLETTER_FIXED_COST) ? NEWSLETTER_FIXED_COST : 0 , 
                                     :unit_cost => 0.01,
                                     :start_date => Date.today)
      rescue Exception =>e
        ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
      end

      @templates = NewsletterEditor.user_templates.reject { |key, val| key.match(/^Header$|^Footer$/)}.keys
    end

    def edit
      @newsletter = Newsletter.find(params[:id])
      @templates = NewsletterEditor.user_templates.keys
    end
    
    def destroy
      Newsletter.find(params[:id]).destroy
      redirect_to :action => :index
    end

    def update
      @newsletter = Newsletter.find(params[:id])
      save
      redirect_to :action => :edit, :id => @newsletter.id
    end

    def section
      @idx = params[:idx]
      @newsletter_template = NewsletterEditor.templates[params[:id]]

      render :layout => false
    end

    # deliver 1 copy ... or thousands
    #
    def deliver
      newsletter_id = params[:id].to_i
      email_addr = params[:email].blank? ? params[:custom_email] : params[:email]

      # send_log_to = Rails.env == 'production' ? (Rails.application.class)::EMAIL_TO_DEFAULT : (Rails.application.class)::EMAIL_TO_DEVELOPER

      command = "RAILS_ENV=#{Rails.env}  #{Rails.root}/script/bash_runner.sh newsletter_emailer NEWSLETTER=#{newsletter_id}"
      command += " EMAIL_ADDR_OVERRIDE=#{email_addr}" if email_addr
      command += " &"

      Rails.logger.warn("Sending newsletter with command #{command}")
      pid = spawn(command)

      flash[:message] = "started job_runner to do delivery of newsletter # #{newsletter_id} w/ pid #{pid}"
      redirect_to :action => :show, :id => newsletter_id
    end

    def kill
      @newsletter = Newsletter.find(params["id"].to_i)
      @newsletter.update_attributes :kill => true
      redirect_to :action => :show, :id => @newsletter.id
    end

    def nl_status
      @newsletter = Newsletter.find(params["id"].to_i)
      render :partial => 'status', :layout => false
    end

    private

    def save
      Newsletter.transaction do
        verbose = false
        puts "==== save NEWSLETTER params = #{params.inspect}" if verbose
        puts "                     newsletter = #{params[:newsletter].inspect}"  if verbose
        puts "                     type       = #{params[:type].inspect}"  if verbose
        puts "                     idx        = #{params[:idx].inspect}" if verbose
        puts "                     order      = #{params[:order].inspect}" if verbose
        puts "                     section    = #{params[:section].inspect}" if verbose
        @newsletter.update_attributes(params[:newsletter])
        return unless params[:type]

        params[:type].size.times do |ii|

          order        = ii                  # we're processing in order
          idx          = params[:idx][ii]    # 
          section_det  = params[:section].andand[idx]
          section_type = params[:type][ii]
          
          next if section_det.nil? 

          section_id   = section_det["id"]

          puts "    save section idx #{idx} // order #{order} // #{section_type} // #{section_det.inspect}" if verbose

          save_section(section_det, section_type, order)
        end
        
        ( (@newsletter.sections || []) - (@sections || []) ).each &:destroy
      end
    end

    def save_section(section_details, type, order)
      verbose = false
      puts "    ==== save SECTION" if verbose

      id = section_details["id"]

      puts "*** PARAM new = #{ section_details[:id].blank?}" if verbose
      puts "      * section_details = #{section_details}" if verbose
      puts "      * id = #{id}" if verbose
      section = id.blank? ? 
                @newsletter.sections.new :
                @newsletter.sections.find_by_id(id) 


      puts "      * type = #{type}"               if verbose
      puts "      * order = #{order.inspect}"     if verbose
      puts "      * section = #{section.inspect}" if verbose

      section.update_attributes(:section => type, :sequence => order)
      
      # Remember which sections we've seen
      @sections ||= []
      @sections << section

      save_fields(section, section_details)
    end

    def save_fields(section, section_details)
      verbose = false
      puts "        ==== save FIELD #{section.inspect} // #{section.inspect}" if verbose
      fields = NewsletterEditor.templates[section.section].fields
      fields.each do |field_name, type|
        data = section_details[field_name]
        puts "          * field_name = #{field_name}" if verbose
        puts "          * type       = #{type}" if verbose
        puts "          * data       = #{data}" if verbose

        if type == 'upload'
          next if data.blank?
          data = save_file(params[:section][idx][field_name],section)
        end
        
        field = section.fields.find(:first, :conditions => { :field => field_name }) ||
          section.fields.new(:field => field_name)
        puts "          * field       = #{field}"         if verbose
        field.update_attributes(:data => data)
      end
    end

    def save_file(file,section)
      extension = file.original_filename.split('.').last
      filename = "#{section.id}.#{extension}"
      local_path = File.join(Rails.root, 'public', 'newsletter_static', filename)
      case file
      when ActionController::UploadedStringIO
        File.open(local_path,'w') { |f| f << file.read }
      when ActionController::UploadedTempfile
        FileUtils.copy file.local_path, local_path
      else
        # XYZFIX P3 
        #   this is a hack - upgrading to rails 2.3 may have broken this?  
        #   not sure.
        #
        File.open(local_path,'w') { |f| f << file.read }
      end
      File.chmod(0444, local_path)

      "http://#{request.domain}#{request.port_string}/newsletter_static/#{filename}"
    end

  end
end

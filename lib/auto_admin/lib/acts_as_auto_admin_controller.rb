module ActsAsAutoAdminController
  
  def acts_as_auto_admin_controller
    
    define_method(:index) do 
      @class = get_class()
      
      # when processing is split over two machines (e.g. heavyink WEB
      # frontend and BACKEND for printer), we use this to pass flash
      # messages back and forth
      #
      flash[:message] = params["flash"] if params["flash"]

      if  params[:search_str]
        # prep the search string
        #
        search_str = params[:search_str]
        search_str = "%" + search_str.to_s + "%"
        
        # find which column to search
        search_col = (@class.methods.include?("name_column_equiv") && @class.name_column_equiv) || "name"
        @items = @class.paginate_by_sql(["SELECT * FROM #{@class.table_name} WHERE #{search_col} like ? ", search_str], 
                                        { :per_page => 50, :page => (params[:page] || 1) })
        
        if @items.size == 1
          return redirect_to(:action => :show, :id => @items.first.id) 
        elsif @items.empty?
          flash[:message] = "none found matching search '#{search_str}'"
          @items = @class.paginate( :page => params[:page] || 1, :per_page => 50)
        end
      elsif params[:search_id]
        
        search_id = params[:search_id]
        search_id = @class.search_preprocess(search_id) if @class.methods.include?("search_preprocess")
        search_id = search_id.to_i
        
        return redirect_to(:action => :show, :id => search_id) 
      else
        @items = @class.paginate( :page => params[:page] || 1, :per_page => 50)
      end
      
      
    end
    
    define_method(:show) do 

      # when processing is split over two machines (e.g. heavyink WEB
      # frontend and BACKEND for printer), we use this to pass flash
      # messages back and forth
      #
      flash[:message] = params["flash"] if params["flash"]

      @class = get_class()
      @item = @class.find(:first, :conditions => "#{@class.primary_key} = #{params[:id]}")
      unless @item
        flash[:message] = "no #{@class.to_s} found with #{@class.primary_key} == '#{params[:id]}'"
        return redirect_to :action => :index
      end
      # puts "here-1"
      # if self.respond_to?(:use_default_views) && use_default_views()
      #   puts "here-2
      #   return render :action => "../shared/show"
      # end
    end
    
    define_method(:edit) do 
      @class = get_class()
      @item = @class.find(params[:id])
      
    end
    
    define_method(:update) do 
      verbose = false
      puts "AAAA update-1 #{params.inspect}" if verbose

      @class = get_class()
      @item = @class.find(params[:id])
      unless @item
        flash[:error] = "invalid item (id == #{params[:id]})"
        redirect_to :action => :index
      end

      begin
        # All fields will arrive as text strings.
        # If admin leaves a field empty in the form, value == ""
        #
        # We don't want to overwrite NULL with ""
        #
        values = params[@class.to_s.underscore]
        puts "AAAA-1 #{values.inspect}" if verbose
        new_values = values.reject {|k, v|
          puts "k == #{k.inspect}"
          v == "" &&  @item.attributes[k].nil? 
        }
        puts "AAAA-2 #{new_values.inspect}" if verbose
        puts "AAAA-3 #{@item.inspect}" if verbose

        @item.update_attributes(new_values, { :without_protection => true })        
        @item.save!

        puts "AAAA-4 #{@item.inspect}" if verbose
        
        flash[:message] = "success - #{@item.respond_to?(:name) ? @item.name : @item.id} updated"
      rescue Exception => e
        flash[:message] = "failure - #{e.message}" 
      end
      redirect_to :action => :show, :id => @item.id
    end
    
    define_method(:new) do 
      @class = get_class()
      @item = @class.new(params[@class.to_s])
    end
    
    define_method(:create) do 
      @class = get_class()
      begin
        @item = @class.create!(params[@class.to_s.underscore])
        flash[:message] = "success - #{@item.respond_to?(:name) ? @item.name : @item.id} created"
        redirect_to :action => :show, :id => @item.id
      rescue 
        flash[:error] = "item not created error - #{$!}"
        redirect_to :action => :index
      end
      
    end

    define_method(:destroy) do 
      @class = get_class()
      @item = @class.find(:first, :conditions => "#{@class.primary_key} = #{params[:id]}")
      @item.destroy
      flash[:message] = "destroyed - #{@class.name} :: #{@item.name}"
      redirect_to :back
      
    end
    
    
  end

end


# make this method available to all controllers
ActionController::Base.extend ActsAsAutoAdminController

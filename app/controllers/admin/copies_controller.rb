class Admin::CopiesController < Admin::Base
  def get_class() Copy end
  
  def setup
    @videos =    Video.find(:all, :order => "name" ).map {|x| [ x.name, x.product_id ]  }
  end
  
  def index
    @death_types = DeathType.find(:all, :conditions => "name != 'live'")

    if (! params[:deathType].nil?)
      @copys = Copy.find(:all, :conditions =>"mediaformat = 2 AND deathType = #{params[:deathType]}")
    else
      @copys = Copy.find(:all, :conditions =>"mediaformat = 2", :limit => 100)
    end

  end

  def search
    @copy = Copy.find(Copy.sticker_to_id(params[:search_str]))
    redirect_to :action => :show, :id =>@copy
  rescue Exception  => e
    flash[:error] = e.message
    redirect_to :back
  end
  
  def show
    @copy = Copy.find(params[:id])
    
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @copy.to_xml }
    end
  end
  
  
  def new
    @copy = Copy.new
    @vendors = Vendor.find(:all, :order=>"name").map {|x| [ x.name, x.vendorID ]  }
    @videos = Video.find(:all, :conditions => ["vendorID = ?", params[:q]], :limit=>20)
  end
  
  def mark_as_in
    @copy = Copy.find(params[:id])
    count = @copy.return_to_stock_multiple(params[:all_but_lastP].to_bool)
    flash[:notice] = "#{count} line items marked as returned"
    redirect_to :action => :show, :id =>@copy
  end
  
  def mark_as_good
    @copy = Copy.find(params[:id])
    who = Person.find(params[:who])
    dl = DeathLog.new(:newDeathType => 0, :editDate =>Date.today, :note=>"verified OK by #{who.to_s} via tvr-master", :copy_id =>@copy.id)
    @copy.status = 1;
    @copy.deathType = 0;
    @copy.save
    dl.save
    flash[:notice] = "copy marked as good"
    redirect_to :action => :show, :id =>@copy
  end
  
  def destroy_copy
    res = nil
    copy_id = params[:id]
    
    copy = Copy.find(copy_id)
    if copy.nil?
      res = "no such copy"
    else
      who = Person.find(params[:who])
      override_li_P = (who.authority_destroy_copy)
      # "#{who}, #{override_li_P}"
      res = copy.clean_delete(override_li_P)
      if (res == true)
        flash[:notice] = "deleted copy #{copy_id}"
        redirect_to :controller => :products, :action => :show, :id =>copy.product.id
        return
      end
    end
    flash[:error] = "failed to destroy copy #{copy_id}: #{res}"
    redirect_to :controller => :copies, :action => :show, :id =>copy
  end
  
  
  def edit
    setup
    @copy = Copy.find(params[:id])
    @states = DeathLog::STATES_TEXT_TO_CODE
  end
  
  def create
    videoArray = Array.new
    if  (! params[:set_id].nil?)
      set = ProductSet.find(params[:set_id])
      set.product_set_memberships.sort_by{|sm| sm.ordinal}.each do |sm|
        videoArray.push(Video.find(sm.product_id))
      end
    else (! params[:video_id].nil?)
      videoArray.push(Video.find(params[:video_id]))
    end
    
    # postCondition: videoArray is populated with product_ids
    
    errorP = false
    successArray = Array.new
    count = 0
    begin
      videoArray.each do |tt|
        
        cc = Copy.new(:birthDATE=>Date.today, :product_id => tt.product_id)
        cc.save
        successArray.push "#{tt.name} : copy_id =  #{cc.sticker_id} #{ (tt.handout.to_s == "") ? "" : "; handout = " + tt.handout}"
      end
    rescue
      raise $!.inspect
      errorP = true
    end
    
    respond_to do |format|
      if errorP
        flash[:error] = 'Error creating copy ; not all copies requested'
      end
      if (successArray.size > 0)
        flash[:notice] = ("Created:<br>" + successArray.join("<br>")).html_safe
      end
      format.html { redirect_to :controller => "admin/products", :action => :show, :id => params[:video_id] }
    end
  end
  
  def update_status
    # normally we write something like this:
    #    update_attributes
    # but we can't do that, because the partial that invokes this doesn't use the normal
    # form_for stuff...in some cases, we don't have an id when we render the partial - we ask
    # the user for an id.
    #
    params[:return_action] ||= :show
    if ! params[:status].nil?
      begin
        @copy = Copy.find(Copy.sticker_to_id(params[:id]))
        @copy.mark_dead(params[:status].first.to_i, "updated via tvr-master by employee #{params[:employee_number]} - #{params[:note]}")
        flash[:notice] = "Status of #{params[:id]} was successfully updated to '#{DeathType.find(params[:status].first.to_i).name}'"
      rescue
        flash[:error] = "error updating status.  error msg: #{$!}"
      end
      redirect_to :controller=> :copies, :action => params[:return_action], :id => params[:id]
      return
    end
  end

  def update_for_polishing
    begin
      @copy = Copy.find_by_sticker(params[:stickerID])
    rescue Exception => e
      flash[:error] = e.message
      return redirect_to :controller=> :purchasings, :action => :polishable
    end

    code = 
      case params[:commit]
      when "fixed" then         DeathLog::DEATH_NOT_DEAD
      when "totally dead" then  DeathLog::DEATH_SCRATCHED_IRREVOCABLE
      else                  raise "illegal button!"
      end
    
    @copy.mark_dead(code, "via polishing")
    flash[:notice] = "Copy #{params[:stickerID]} set to #{params[:commit]}"
    redirect_to :controller=> :purchasings, :action => :polishable
  end
  
  def update
    @copy = Copy.find(params[:id])
    
    if ( params[:confirm] != "confirm")
      flash[:error] = 'Failed to type confirmation text - no change made'
      setup
      render :action => "edit"
      return
    end
    
    if ! params[:copy][:status].nil?
      @copy.mark_dead(params[:copy][:status].to_i, "updated via tvr-master by employee #{params[:employee_number]} - #{params[:note]}")
      flash[:notice] = 'Status was successfully updated.'
      redirect_to  :action => :show, :id =>@copy
      return
    end
    
    if @copy.update_attributes(params[:copy])
      flash[:notice] = 'Copy was successfully updated.'
      redirect_to params[:return_action].nil? ? { :action => :show, :id =>@copy } : { :action=>:returns}
    end
  end
  
  
  def make_copies_visible
    Copy.make_copies_visible
    flash[:notice] = 'Copies made visible to shippers.'
    redirect_to  :action => :index
  end
  
  def returns
  end
  
  def return_one
    @sticker = params[:sticker]
    copy_id = Copy.sticker_to_id(@sticker)
    copy = Copy.find_by_copy_id(copy_id)
    raise "no such copy #{@sticker}" if copy.nil?
    
    # ressurrects copy on certain deathtypes
    copy.return_to_stock

    if copy.status == 1
      return render :return_one
    else
      @msg = (copy.death_type_id == DeathLog::DEATH_SOLD) ?
      "Put copy '#{@sticker}' in 'Craig' Bin" :
        "Put copy '#{@sticker}' in 'Polish' Bin - #{copy.most_recent_death.note} "
      
      render :return_one_error
    end
    
  rescue Exception => e
    @msg = e.message
    render :return_one_error    
  end

  # effectively duplicated in lib/tvr/do.rb, db_consistency_check()
  def consistency
    @in_and_out_not_one = Copy.ERRORCHECK_in_and_out_not_one
    @lost_and_here      = Copy.ERRORCHECK_lost_and_actually_here
  end
end

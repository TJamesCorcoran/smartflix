class Admin::InventoriesController < Admin::Base

  #--------------------
  # user visible pages

  def index
    @freshness_pct =  Inventory.freshness_percent
    @inventories = Inventory.find(:all, :limit => 20, :order=>"inventoryID desc")
  end

  def show
    @inventory = Inventory.find(params[:id].to_i)
  end

  def start
    @inventory = Inventory.new
    @suggest_start = Inventory.suggest_start

    @inventory.startID = @suggest_start
    @inventory.endID = (@inventory.startID + 200) if @inventory.startID

    if request.post?
      start_id = Copy.sticker_to_id(params["inventory"]["startID"])
      end_id = Copy.sticker_to_id(params["inventory"]["endID"])
      session[:inventory] = {}
      session[:inventory][:present_ids] = []
      session[:inventory][:missing_ids] = []
      session[:inventory][:returned_ids] = []
      session[:inventory][:found_ids] = []
      session[:inventory][:misfiled_ids] = []

      session[:inventory][:start_id] = start_id
      session[:inventory][:end_id] = end_id
      session[:inventory][:expected_id] = Copy.next_instock_inrange(session[:inventory][:start_id] - 1, session[:inventory][:end_id])
      redirect_to :action => :in_progress
   end

  end

  def in_progress
    @expected_id = 
      session[:inventory][:expected_id] ||
      Copy.next_instock_inrange(session[:inventory][:start_id] - 1, session[:inventory][:end_id])
  end

  def done
    @new_inventory = nil
    
    if request.post?
      session[:inventory][:present_ids].each do |id|
        Copy.find(id).return_to_stock
      end
      
      session[:inventory][:missing_ids].each do |id|
        Copy.find(id).mark_as_lost_in_house
      end
      
      begin 
        @new_inventory = Inventory.create!(:inventoryDate => Date.today, 
                                           :startID => session[:inventory][:start_id],
                                           :endID => session[:inventory][:end_id],
                                           :copyCount => session[:inventory][:present_ids].size,
                                           :misfiledCount => session[:inventory][:misfiled_ids].size,
                                           :missingCount => session[:inventory][:missing_ids].size,
                                           :foundCount => session[:inventory][:found_ids].size,
                                           :returnedCount => session[:inventory][:returned_ids].size)
      rescue
      end
    else
      @new_inventory = Inventory.find(:last)
    end
  end


  def ignore_button
    @success     = true
    @expected_id = nil
    @window      = :text
    @msg         = ""
    
    
    return render :action => :render_it
  end

  def one_misfiled_button
    set_present(session[:inventory][:this_id])
    set_present(session[:inventory][:expected_id])
    set_misfiled(session[:inventory][:this_id])
    text = "#{session[:inventory][:this_id]} - misfiled. Refile.<br>"  +
      "#{session[:inventory][:expected_id]} - here<br>" 
    # NOTE: we do not call incr_expectation() 
    
    @success     = true
    @expected_id = session[:inventory][:expected_id]
    @window      = :text
    @msg         = text
    
    return render :action => :render_it
  end

  def missing_button
    session[:inventory][:skipped_ids].each do |id| 
      set_missing(id.to_i)
    end

    set_present(session[:inventory][:this_id])
    text = session[:inventory][:this_id].to_s + " - here<br>" + 
      session[:inventory][:skipped_ids].join(",") + " - missing"
    incr_expectation
    
    @success     = true
    @expected_id = session[:inventory][:expected_id]
    @window      = :text
    @msg         = text
    
    return render :action => :render_it
  end

  #--------------------
  # record status

 private
  def incr_expectation
    session[:inventory][:prev_id] = session[:inventory][:this_id]
    session[:inventory][:this_id] = nil
    exp = Copy.next_instock_inrange(session[:inventory][:prev_id], session[:inventory][:end_id])
    session[:inventory][:expected_id] = exp
  end

   def set_present(id) 
     session[:inventory][:missing_ids] -= [id]
     session[:inventory][:present_ids] << id
   end

   def set_returned(id)
     session[:inventory][:present_ids] << id
     session[:inventory][:returned_ids] << id
   end

   def set_found(id)
     session[:inventory][:present_ids] << id
     session[:inventory][:found_ids] << id
   end

   def set_missing(id)
     session[:inventory][:missing_ids] << id
   end

   def set_misfiled(id)
     session[:inventory][:misfiled_ids] << id
   end

public

  def scan_dvd
    status_str = nil
    success = nil
    
    return missing_button      if params["barcode"] == "YYYY"
    return one_misfiled_button if params["barcode"] == "NNNN"
    
    begin
      scanned_id = Copy.sticker_to_id(params["barcode"])
    rescue
      @success     = false
      @expected_id = nil
      @window      = :text
      @msg         = "#{params["barcode"]} - invalid id"
      
      return render :action => :render_it
    end
    
    session[:inventory][:this_id] = scanned_id
    prev_id = session[:inventory][:prev_id] || (session[:inventory][:start_id] - 1)
    
    # range check
    #
    if scanned_id < session[:inventory][:start_id]  ||
        scanned_id > session[:inventory][:end_id]
      set_misfiled(scanned_id)
      
      @success     = false
      @expected_id = nil
      @window      = :text
      @msg         = "#{scanned_id} - out of range"
      
      return render :action => :render_it
    end
    
    # duplicate check
    # 
    if scanned_id == prev_id
      
      @success     = true
      @expected_id = nil
      @window      = :text
      @msg         = "#{scanned_id} - duplicate scan; prev = #{prev_id}"
      
      return render :action => :render_it
    end
    
    # stage 1: expected, unexpected, broken, what?
    #
    copy = Copy.find_by_copy_id(scanned_id)
    if copy.nil?
      
      @success     = false
      @expected_id = nil
      @window      = :text
      @msg         = "Remove ID #{scanned_id} and attach sticky: missing copy info in DB"
      
      return render :action => :render_it
    end 
    
    if copy.expect_in_drawer?
      status_str = "here"
      success = true
      set_present(scanned_id)
    elsif copy.thought_lost?
      status_str = "thought was lost ;returned to stock"
      success = true
      set_found(scanned_id)
    elsif copy.times_out > 0
      status_str = "thought was with customer ;returned to stock"
      success = true
      set_returned(scanned_id)
    end
    
    
    if ! copy.live?
      if copy.returnable_to_stock?
        copy.mark_live
        copy.return_to_stock
      else ! copy.returnable_to_stock?
        status_str = "Remove ID #{scanned_id} and attach sticky: broken"
        success = false
        set_misfiled(scanned_id)
      end
    end
    
    # stage 2: ordering, reverse 2, skip a block
    #
    #
    
    # reverse order check
    #
    if scanned_id < prev_id
      set_misfiled(scanned_id)
      set_present(scanned_id)
      
      @success     = false
      @expected_id = nil
      @window      = :text
      @msg         = "#{scanned_id} - misfiled.  Please refile."
      
      return render :action => :render_it
    end
    
    # We only care about alerting the user about out-of-order here, though
    # we do use some heuristics: if a single expected video is skipped we
    # ask the user to make sure they didn't accidentally skip one, and if
    # more than one expected video is skipped we ask them if the video
    # just scanned might not be misfiled
    
    skipped = Copy.good_between_ids(session[:inventory][:expected_id], scanned_id )
    number_skipped = skipped.size
    
    if number_skipped == 1
      session[:inventory][:skipped_ids] = skipped
      msg = "Missing copy #{ Copy.id_to_sticker(skipped.first) } - really missing?" # "
      
      @success     = false
      @expected_id = nil
      @window      = :one
      @msg         = msg
      
      return render :action => :render_it
    elsif number_skipped > 1
      session[:inventory][:skipped_ids] = skipped
      msg = "Missing copies #{ skipped.map {|id| Copy.id_to_sticker(id)}.join(',') } - really missing?" # "

      @success     = false
      @expected_id = nil
      @window      = :many
      @msg         = msg

      return render :action => :render_it
    end
    
    incr_expectation
    @success     = true
    @expected_id = session[:inventory][:expected_id]
    @window      = :text
    @msg         = "#{scanned_id} - #{status_str}"
    
    return render :action => :render_it
  end


  def answer_question
  end

end

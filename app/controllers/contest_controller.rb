class ContestController < ApplicationController

  skip_before_filter :track_first_request, :store_browse_history, :track_origin,  :track_current_url, :only => [:image_lightbox]

  def index
    if params[:vote]
      # "smartflix.com/contest?vote=73"
      # allows us to link to "vote for my project" succinctly.  if not in
      # voting phase, params[:vote] gets ignored (see show action); but if in
      # entry phase, we do have a ping request form for folks who came to vote.
      # If it is, the entry indicated by the get param will be pre-selected for
      # vote (see vote action).
      @contest = ContestEntry.find(params[:vote]).contest
      if @contest.phase != Contest::VOTING_PHASE
        flash[:message] = "Voting has not yet started for this contest."
      end
    else
      # "smartflix.com/contest"
      @contests = Contest.active
      if @contests.length == 0
        # if no contests are active (in either entry or voting phase), show the
        # page for the most recently concluded contest (which will show the
        # winners)
        @contest = Contest.most_recently_concluded
      elsif @contests.length == 1
        # if only one contest is active, show its page
        @contest = @contests.first
      end
    end
    # if we don't have an @contest by this point, it means there are multiple
    # active contests, so we'll do a list page.
    if @contest
      redirect_to :action => :show, :id => @contest, :vote => params[:vote]
    else
      redirect_to :action => :list
    end
  end

  def list
    @contests = Contest.active
    # render a page showing current active contests, with links for each
  end

  def show
    if !params[:id]
      redirect_to :action => ''
      return
    end
    @contest = Contest.find(params[:id])
    @previous_contest = Contest.find_by_contest_id(@contest.id - 1)
    @next_contest = Contest.find_by_contest_id(@contest.id + 1)

    @crumbtrail = Breadcrumb.for_contest_show(@contest)
    case @contest.phase
    when Contest::ENTRY_PHASE
      @contest_ping_request = ContestPingRequest.new
      if @customer
        @contest_ping_request.email = @customer.email
        # see whether customer has already entered
        @your_entry = @contest.contest_entries.find_by_customer_id(@customer)
      end
      if !@your_entry
        # set up a new entry for them to fill in
        @contest_entry = ContestEntry.new
        if @customer
          @contest_entry.customer = @customer
          # Customers can put a different name on their contest entries
          @contest_entry.first_name = @customer.first_name
          @contest_entry.last_name  = @customer.last_name
        end
      end
    when Contest::VOTING_PHASE
      session[:contest_votes]              ||= []
      session[:contest_votes][@contest.id] ||= []
      # if arrived here by a "vote=" link, pre-select the indicated entry
      # otherwise initialize an empty array for the form
      @selected = params[:vote] ? [params[:vote].to_i] : []
      if @customer
        @your_entry = @contest.contest_entries.find_by_customer_id(@customer)
        @voter_email = @customer.email
        votes = @contest.contest_votes_by_voter_email(@voter_email)
        @your_votes = votes.map { |v| ContestEntry.find(v.contest_entry_id) }
      else
        @your_votes = session[:contest_votes][@contest.id].map { |id| ContestEntry.find(id) }
      end
    when Contest::ARCHIVE_PHASE
      @your_entry = @contest.contest_entries.find_by_customer_id(@customer)
    end
  end

  def notify
    @contest = Contest.find(params[:id])
    @contest_ping_request =
      ContestPingRequest.new(params[:contest_ping_request])
    email = @contest_ping_request.email
    # if request is a duplicate, just ignore & pretend to submit
    if !ContestPingRequest.find_by_contest_id_and_email(@contest.id, email)
      @contest_ping_request.contest = @contest
      if !@contest_ping_request.save
        redirect_to_contest("Invalid email address.")
        return
      end
    end
    redirect_to_contest("Thanks, we'll let you know when voting starts!")
  end

  # in entry phase, entry form posts to here
  def enter
    # Make sure photos param isn't blank... this protects us from 500
    # errors from spam bots without allowing them to post... (hope!)
    unless params[:photos]
      flash[:message] = "At least one photo is required"
      return redirect_to( :action => :list)
    end
    # Make sure there aren't any crazy-large photos being submitted
    if params[:photos].any? { |p| p.size >= 10.megabytes }
      render_contest("At least one of your photos is over 10 megabytes, please submit a smaller image file")
      return
    end
    # determine whether this is the optional "edit" portion of the
    # entry process, and either grab the new entry or make one.
    if params[:edit]
      @contest_entry = ContestEntry.find(params[:edit])
      @contest = @contest_entry.contest
    else
      @contest = Contest.find(params[:id])
      @contest_entry = ContestEntry.new(params[:contest_entry])
    end
    @crumbtrail = Breadcrumb.for_contest_enter(@contest)
    if !@customer && !entry_form_customer
      render_contest
      return
    end
    # Make sure there aren't any crazy-large photos being submitted
    if params[:photos].any? { |p| p.size >= 10.megabytes }
      return render_contest("At least one of your photos is over 10 megabytes, please submit a smaller image file")
    end
    # sum up the sizes of submitted photos to make sure there's at least one
    if params[:photos].inject(0){ |s, u| s + u.size } == 0
      render_contest("Please include at least one photo.")
      return
    end
    # if they weren't logged in before, they've just either entered a password
    # or registered a new account; might as well log them in now
    session[:customer_id] = @customer.id
    begin
      if !@contest.add_entry(@contest_entry, @customer)
        # TODO: validate presence of first & last name?
        redirect_to_contest("Please include a title for your project.")
        return
      end
      # In case we're editing an already saved entry, replace any photos
      @contest_entry.contest_entry_photos.each{ |photo| photo.destroy }
      @contest_entry.contest_entry_photos = []
      params[:photos].each do |upload|
        if upload.size != 0
          photo = ContestEntryPhoto.new(:uploaded_data => upload)
          @contest_entry.contest_entry_photos << photo
        end
      end
    rescue CustomerAlreadyEntered
      redirect_to_contest("You have already entered this contest.")
      return
    rescue ContestEntryError => e
      logger.error e.message
      redirect_to_contest
      return
    end
    # renders preview of entry edit form.
  end

  def edit
    @contest_entry = ContestEntry.find(params[:id])
    if !@contest_entry || !@customer
      redirect_to :action => :index
      return
    end
    if @contest_entry.customer != @customer
      raise "Security violation: someone is trying to edit someone elses entry"
    end
    @contest = @contest_entry.contest
    @crumbtrail = Breadcrumb.for_contest_edit(@contest)
    @contest_entry.update_attributes(params[:contest_entry])
    if !@contest_entry.save
      flash.now[:message] = "Please include a title for your project."
    end

    params[:photos] ||= []

    # Make sure there aren't any crazy-large photos being submitted
    if params[:photos].any? { |p| p.size >= 10.megabytes }
      return render_contest("At least one of your photos is over 10 megabytes, please submit a smaller image file")
    end
    # any photos submitted will replace previous ones
    if params[:photos].inject(0){ |s, u| s + u.size } > 0
      @contest_entry.contest_entry_photos.each{ |photo| photo.destroy }
      @contest_entry.contest_entry_photos = []
      params[:photos].each do |upload|
        if upload.size != 0
          photo = ContestEntryPhoto.new(:uploaded_data => upload)
          @contest_entry.contest_entry_photos << photo
        end
      end
    end
    if params[:commit_and_finish]
      redirect_to_contest("Thanks for entering!")
    else
      flash.now[:message] = "Thanks for entering!"
      render :action => :enter, :edit => @contest_entry
    end
  end

  def vote
    @contest = Contest.find(params[:id])
    @crumbtrail = Breadcrumb.for_contest_vote(@contest)
    @voter_email = find_voter
    if @contest.has_been_voted_in_by(@voter_email)
      render_contest "You have already voted in this contest."
      return
    end
    @selected = params[:selected].andand.map{ |id| id.to_i }
    # if the form isn't fully filled out, return to it
    if !@voter_email || !@selected
      render_contest
      return
    end
    if @selected.length != ContestVote::MAX_PER_VOTER
      render_contest("Please make #{ContestVote::MAX_PER_VOTER} selections.")
      return
    end
    begin
      @selected.each do |id|
        @contest.cast_vote(ContestEntry.find(id), @voter_email)
      end
      # remember the votes placed for this session, in case this isn't
      # a logged-in customer
      session[:contest_votes][@contest.id] = @selected
    rescue ContestVotingError => e
      logger.error e.message
      redirect_to_contest
      return
    end
    redirect_to_contest("Thanks for voting!")
    return
  end

  def image_lightbox
    @photo = ContestEntryPhoto.find(params[:id])
    @photo = @photo.parent if @photo.parent
    render :layout => false
  end

  private

  def redirect_to_contest(message = nil)
    flash[:message] = message if message
    redirect_to :action => :show, :id => @contest
  end

  def render_contest(message = nil)
    flash.now[:message] = message if message
    render :action => :show
  end

  def entry_form_customer
    if params[:login_email].andand.empty? &&
        params[:login_password].andand.empty?
      if params[:register_email]
        if (customer = register_entrant)
          return customer
        else
          return nil
        end
      end #of attempt to register
    else
      if (customer = login(params[:login_email], params[:login_password]))
        return customer
      else
        flash.now[:message] = "Login to existing account failed, try again?"
        return nil
      end #of attempt to login
    end
    # couldn't do either
    flash.now[:message] = "Please login or register a new account"
    return nil
  end

  def login(email, password)
    @customer = nil
    customer = Customer.authenticate(email, password)
    if (customer)
      session[:customer_id] = customer.id
      session[:timestamp] = Time.now.to_i
      setup_customer
      return customer
    else
      return nil
    end
  end

  def register_entrant
    params[:register_password] ||= RandomChars.true_random_chars(8)
    params[:register_confirmation] ||= params[:register_password]
    new_customer = Customer.new({:email => params[:register_email],
                                 :password => params[:register_password],
                                 :password_confirmation => params[:register_password_confirmation]})
    new_customer.first_name = params[:contest_entry][:first_name]
    new_customer.last_name  = params[:contest_entry][:last_name]
    if new_customer.valid?
      new_customer.save!
      begin
        SfMailer.welcome(new_customer)
      rescue Net::SMTPFatalError
      end
      session[:customer_id] = new_customer.id
      session[:timestamp] = Time.now.to_i
      setup_customer
      return new_customer
    else
      flash.now[:message] = new_customer.errors.full_messages.join(': ')
      return nil
    end
  end

  def find_voter
    if @voter_email
      return @voter_email
    elsif @customer
      return @customer.email
    elsif params[:voter_email]
      if params[:voter_email] !~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
        flash.now[:message] = "Invalid email address."
        return nil
      else
        return params[:voter_email]
      end
    else
      flash.now[:message] = "Please enter an email address, or log in."
      return nil
    end
  end


end

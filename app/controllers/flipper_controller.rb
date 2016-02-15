class FlipperController < ApplicationController

  skip_before_filter :track_first_request, :store_browse_history, :track_origin,  :track_current_url

  before_filter :flash_keeper

  def index
    # this may be hitting a fly w a howitzer - do we really want to turn off flippers for all
    # customer?
    #
    # 2011 decision - yes, I think so. SF is in decline, and we just
    # want to simplify.  We're never going to use flippers again.
    #
    if @customer
      return render :nothing => true 
    end

    session[:flipper] ||= {}

    clear_non_sticky_flippers

    @promotions = get_flipper_settings( params[:id], params[:url] )
  end

  def switch
    return unless params[:id] and params[:n] and session[:flipper]
    @promo = Promotion.find(params[:id])

    session[:flipper][params[:id].to_i] = params[:n].to_i

    @index = params[:n].to_i
  end

  def next
    return unless params[:id] and session[:flipper]
    @promo = Promotion.find(params[:id])

    session[:flipper][params[:id].to_i] = session[:flipper][params[:id].to_i].to_i + 1
    session[:flipper][params[:id].to_i] = 0 if session[:flipper][params[:id].to_i].to_i >= @promo.ordered_pages.size

    @index = session[:flipper][params[:id].to_i].to_i
 end

  def previous
    return unless params[:id] and session[:flipper]
    @promo = Promotion.find(params[:id])

    session[:flipper][params[:id].to_i] = session[:flipper][params[:id].to_i].to_i - 1
    session[:flipper][params[:id].to_i] = @promo.ordered_pages.size-1 if session[:flipper][params[:id].to_i].to_i < 0

    @index = session[:flipper][params[:id].to_i].to_i
  end

  def close
    return unless params[:id] and session[:flipper]
    @promo = Promotion.find(params[:id])

    session[:flipper][params[:id].to_i] = 'closed'
  end

  def minimize
    return unless params[:id] and session[:flipper]
    @promo = Promotion.find(params[:id])

    @out = if session[:flipper][params[:id].to_i] == 'minimized'
      session[:flipper][params[:id].to_i] = 0
      @state = @promo.ordered_pages[0].id
      @promo.ordered_pages[0].content
    else
      session[:flipper][params[:id].to_i] = 'minimized'
      @state = 'minimized'
      @promo.minimized_content
    end
  end


  private

  def get_flipper_settings( id = nil, url = '/' )
    if id
      [Promotion.find(id)]
    else
      session[:flipper].map{|key,value| Promotion.find(key) }.reject{|p| !p.on?} | Promotion.find_all_for_audience( first_request? )
    end.map do |promo|
      if applies_to_this_page( url, promo )
        unless flipper = session[:flipper][promo.id]
          if promo.default_status == 'full'
            session[:flipper][promo.id] = 0
            {:promobj => promo, :id => promo.id, :content => promo.ordered_pages[0].content, :state => promo.ordered_pages[0].id}
          else
            session[:flipper][promo.id] = 'minimized'
            {:promobj => promo, :id => promo.id, :content => promo.minimized_content, :state => 'minimized'}
          end
        else
          if flipper == 'minimized'
            {:promobj => promo, :id => promo.id, :content => promo.minimized_content, :state => 'minimized'}
          elsif flipper == 'closed'
            nil
          elsif flipper.is_a?(Integer)
            {:promobj => promo, :id => promo.id, :content => promo.ordered_pages[ flipper ].content, :state => promo.ordered_pages[ flipper ].id}
          else
            flipper = 0
            {:promobj => promo, :id => promo.id, :content => promo.ordered_pages[ flipper ].content, :state => promo.ordered_pages[ flipper ].id}
          end
        end
      else
        nil
      end
    end.compact
  end

  # Parses through the flipper hash in the session, determining if the flippers stored there
  #  should be retained (they're sticky) or destroyed (non-sticky)
  def clear_non_sticky_flippers
    session[:flipper].delete_if do |key, value|
      !Promotion.find_by_promotion_id(key).andand.sticky?
    end
  end

  # Compares the current "#{request.protocol}#{request.host_with_port}#{request.fullpath}" value to the regex in promo.display_page
  def applies_to_this_page( url, promo )
    Regexp.new(promo.display_page).match url
  end

  private

  # Due to the flipper's ajaxian nature, we lose the flash hash when a flipper is loaded.
  #  This ensures that we keep the contents of the flash between page calls.
  def flash_keeper
    flash.keep
  end
end

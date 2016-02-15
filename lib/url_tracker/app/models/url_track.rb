
class UrlTrack < ActiveRecord::Base
  scope :last_24_hrs, :conditions => "created_at >= '#{ (Time.now - (25 * 60 * 60 )).strftime("%Y-%m-%d %H:%M:%S")}'"
  scope :with_customer, :conditions => "customer_id"

  @max_chars = 40


  #----------
  # low-level
  #----------
  def self.get_from_custid(ci, limit = nil)
    UrlTrack.find(:all, 
                  :conditions => "customer_id = #{ci}",
                  :order => "url_track_id desc", 
                  :limit => limit).reverse
  end

  def self.get_from_sessid(si, limit = nil)
    UrlTrack.find(:all, 
                  :conditions => "session_id = '#{si}'",
                  :order => "url_track_id desc", 
                  :limit => limit).reverse
  end



  def self.get_from_timestamp(ts, limit = nil)
    ut = UrlTrack.find(:all, 
                       :conditions => "created_at = '#{ts.strftime("%Y-%m-%d %H:%M:%S")}'")
    if ut.size != 1
      puts "*** error - #{ut.size} hits" 
      ut.each do |ut|
        puts "#{'*' }  #{sprintf("%-#{@max_chars}s", ut.path[0,@max_chars])}  #{sprintf("%-7s", ut.action_id)}  #{ut.created_at}" 
      end
      return
    end

    get_from_sessid(ut.first.session_id, limit)
  end


  #----------
  # printing
  #----------

  def self.print_many(ut, ts = nil)
    @max_chars = 40

    puts "customer id == #{ut.first.customer_id}" 
    ut.each { |ut| 
      puts "#{ut.created_at == ts.andand.to_time ? '-->' : '  *' }  #{sprintf("%-#{@max_chars}s", ut.path[0,@max_chars])}  #{sprintf("%-7s", ut.action_id)}  #{ut.created_at}" 
    }
  end

  #----------
  # med-level
  #----------
  def self.print_from_timestamp(ts, limit = nil)
    ts = DateTime.parse("#{ts} -0400") if ts.is_a?(String)
    ut = get_from_timestamp(ts, limit)
    cust_id = ut.first.customer_id

    print_many(ut, ts)

    puts "offers ===="
    reco_max_chars = 15
    UpsellOffer.find_all_by_customer_id(cust_id).each do |uo|
      puts "#{uo.created_at == ts.andand.to_time ? '-->' : '  *' }  #{sprintf("%-#{reco_max_chars}s", uo.reco_type)}  #{sprintf('%5s', uo.reco_id)}  #{uo.ordinal} #{uo.created_at}" 
    end
    
  end

  def self.print_from_custid(ci, limit = nil)
    print_many(get_from_custid(ci, limit))
  end


end

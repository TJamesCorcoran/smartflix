class KillAllVhsTapes < ActiveRecord::Migration
  def self.up
    Copy.find(:all, :conditions => "mediaformat = 1 and status = 1").each { |copy|
      copy.mark_dead(DeathLog::DEATH_SOLD, "clean up the records; get rid of all VHS tapes on 25 Aug 2010")
    }
  end

  def self.down
  end
end

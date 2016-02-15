class DvdWeight < ActiveRecord::Base
  self.primary_key = "dvd_weight_id"
  attr_protected # <-- blank means total access

  def self.find_weight(boxP, num_dvds)
    find(:first, :conditions => "boxP = #{boxP} and num_dvds = #{num_dvds}")
  end
end

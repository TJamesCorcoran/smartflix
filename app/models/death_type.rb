class DeathType < ActiveRecord::Base
  self.primary_key = "death_type_id"
  attr_protected # <-- blank means total access

  has_many :copies
  has_many :deathLogs, :foreign_key => 'newDeathType'

end

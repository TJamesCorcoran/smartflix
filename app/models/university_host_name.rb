class UniversityHostName < ActiveRecord::Base
  self.primary_key ="university_host_name_id"

  attr_protected # <-- blank means total access


  belongs_to :university

end

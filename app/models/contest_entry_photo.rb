class ContestEntryPhoto < ActiveRecord::Base
  self.primary_key = "contest_entry_photo_id"

  attr_protected # <-- blank means total access


  belongs_to :contest_entry

#RAILS3  has_attachment :content_type => :image,
#                 :storage => :file_system,
                 # :size => 1.byte..10.megabytes,
                 # :resize_to => '440x440>',
                 # :thumbnails => { :thumb => '160x160>' }
#
#  validates_as_attachment

end

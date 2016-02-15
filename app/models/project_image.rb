class ProjectImage < ActiveRecord::Base
  attr_protected # <-- blank means total access

  self.primary_key = 'id'

  belongs_to :project_update

  # has_attachment :content_type => :image,
  #                :storage => :file_system,
  #                :size => 1.byte..10.megabytes,
  #                :resize_to => '440x440>',
  #                :thumbnails => {  :thumb => '200x200>' }

  # validates_as_attachment

end

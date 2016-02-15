class ProjectUpdate < ActiveRecord::Base
  attr_protected # <-- blank means total access


  belongs_to :project
  has_many :images, :class_name => 'ProjectImage'


  # We use mass assignment, so limit inputs for security
  attr_accessible :text

  # Given photos as uploaded with a form, add them to the update
  def add_photos_from_form(photos)
    return if photos.blank?
    photos.select { |photo| photo.size > 0 }.each do |photo|
      self.images << ProjectImage.new(:uploaded_data => photo)
    end
  end

end

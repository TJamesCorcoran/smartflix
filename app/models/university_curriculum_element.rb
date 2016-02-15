class UniversityCurriculumElement < ActiveRecord::Base
  self.primary_key ="university_curriculum_element_id"

  attr_protected # <-- blank means total access

  belongs_to :university
  belongs_to :product, :foreign_key => :video_id
end

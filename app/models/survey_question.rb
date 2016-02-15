class SurveyQuestion < ActiveRecord::Base
  self.primary_key ="survey_question_id"

  attr_protected # <-- blank means total access

  has_many :survey_answers
  belongs_to :survey
end

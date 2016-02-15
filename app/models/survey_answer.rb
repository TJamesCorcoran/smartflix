class SurveyAnswer < ActiveRecord::Base
  self.primary_key ="survey_answer_id"

  attr_protected # <-- blank means total access

  belongs_to :customer
  belongs_to :survey_question
  belongs_to :order
  has_many :customer_contacts

end

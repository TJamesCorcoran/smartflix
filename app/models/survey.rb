class Survey < ActiveRecord::Base 
  self.primary_key ="survey_id"

  attr_protected # <-- blank means total access

  has_many :survey_questions

  # Utility function to get all answers to a survey
  def survey_answers
    survey_questions.map(&:survey_answers).flatten
  end

  # Little utility function for calculating the "One Question" results...
  #  this really belongs in a reporting controller of some kind however,
  #  in the interest of time, I'm just dropping it here for now.
  def one_question_score(last_n=nil)
    answers = survey_questions.map(&:survey_answers).flatten
    answers = answers[last_n * -1, last_n] if last_n && answers.size >= last_n
    count = answers.size.to_f
    positive = answers.select{|a| [9,10].include?(a.answer.to_f) }.size.to_f
    negative = answers.select{|a| (1..6).include?(a.answer.to_f) }.size.to_f
    ((positive/count)-(negative/count)) * 100
  end

  def self.percent_who_give_x_or_higher(x)
    survey = Survey.find(:all, :conditions=>"name = 'One Number'")[0]
    answers = survey.survey_questions.map(&:survey_answers).flatten
    pass_count = answers.select { |answer| answer.answer.to_i >= x }.size
    pass_count / (answers.size * 1.0) 
  end

  
  def self.find_failing_and_unaddressed 
    # find all the failing grades we've received
    failing_orig = Survey.find(:all, :conditions=>"name = 'One Number'")[0].survey_questions[0].survey_answers.select{ |ans| ans.answer.to_i <= 5 }
    
    # then prune from it any items that we've dismissed
    failing = Array.new
    failing_orig.each do |ff|
      allow = true
      ff.customer_contacts.each do |cc|
        if ((cc.customer_contact_type.name == "dismiss") ||
            (cc.customer_contact_type.name == "customer made happy") ||
            (cc.customer_contact_type.name == "customer still unhappy"))
          allow = false
        end
      end
      if (allow) 
        failing.push(ff)
      end
    end
    failing
  end
end

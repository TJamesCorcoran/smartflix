class CreateSurveyQuestions < ActiveRecord::Migration
  def self.up
    create_table( :survey_questions, :primary_key => 'survey_question_id' ) do |t|
      t.column :survey_id, :integer, :null => false
      t.column :question, :string
      t.column :answer_html, :text
      t.column :answer_validator, :string
    end
    
    SurveyQuestion.create :survey_id => 1, 
                          :question => 'How likely are you to recommend us to others on a 1-10 scale?',
                          :answer_html => (1..10).map{|i| %Q{<input type="radio" name="survey_question[1]" value="#{i}" />#{i}&nbsp;}}.join,
                          :answer_validator => "^(10|[1-9])$"
  end

  def self.down
    drop_table :survey_questions
  end
end

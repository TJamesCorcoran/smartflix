class CreateSurveyAnswers < ActiveRecord::Migration
  def self.up
    create_table( :survey_answers, :primary_key => 'survey_answer_id') do |t|
      t.column :customer_id, :integer
      t.column :survey_question_id, :integer
      t.column :order_id, :integer
      t.column :answer, :string
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :survey_answers
  end
end

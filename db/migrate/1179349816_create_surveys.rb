class CreateSurveys < ActiveRecord::Migration
  def self.up
    create_table( :surveys, :primary_key => 'survey_id') do |t|
      t.column :name, :string
    end
    
    Survey.create :name => 'One Number'
  end

  def self.down
    drop_table :surveys
  end
end

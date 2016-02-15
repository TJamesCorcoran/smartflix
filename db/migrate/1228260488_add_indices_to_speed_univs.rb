class AddIndicesToSpeedUnivs < ActiveRecord::Migration
  def self.up
    add_index :university_curriculum_elements, :video_id
    add_index :university_curriculum_elements, :university_id
  end

  def self.down
    remove_index :university_curriculum_elements, :video_id
    remove_index :university_curriculum_elements, :university_id
  end
end

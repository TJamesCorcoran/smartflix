class AddEmailPreferenceTypeUniv < ActiveRecord::Migration
  def up
    EmailPreferenceType.create!(:form_tag => "university", 
                                :name => "University announcements", 
                                :description => "invitations and announcements about SmartFlix universities")
  end

  def down
    EmailPreferenceType.find_by_form_tag("university").destroy
  end
end

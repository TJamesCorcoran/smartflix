class CreateEmailPreferenceTypes < ActiveRecord::Migration
  def self.up
    create_table(:email_preference_types, :primary_key => 'email_preference_type_id') do |t|
      t.column :form_tag, :string, :null => false
      t.column :name, :string, :null => false
      t.column :description, :string, :null => false
    end
    EmailPreferenceType.create(:form_tag => 'announcements',
                               :name => "General Announcements",
                               :description => "General announcements related to our services")
    EmailPreferenceType.create(:form_tag => 'new',
                               :name => "New Products",
                               :description => "Information about new products in categories that you've shown interest in")
    EmailPreferenceType.create(:form_tag => 'recommended',
                               :name => "Recommended Products",
                               :description => "Information about products that we think you'll enjoy based on your previous rentals")
  end

  def self.down
    drop_table :email_preference_types
  end
end

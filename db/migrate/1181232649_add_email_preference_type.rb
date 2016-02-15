class AddEmailPreferenceType < ActiveRecord::Migration
  def self.up
    # Add a key to the email preferences table to speed everything up
    add_index :email_preferences, :customer_id
    new_pref_type = EmailPreferenceType.create(:form_tag => 'newsletters',
                                               :name => "Newsletters",
                                               :description => "Newsletters on topics related to videos you've rented")
    # Do inserts for all customers via direct SQL for speed; group inserts for more speed!
    Customer.find(:all, :include => :email_preferences).collect do |customer|
      # Set them to yes on the new one if there are any other categories marked yes
      send_email = customer.email_preferences.collect(&:send_email).include?(true)
      "(#{customer.id}, #{new_pref_type.id}, #{send_email ? 1 : 0})"
    end.in_groups_of(200, false) do |insert|
      execute "INSERT INTO email_preferences (customer_id, email_preference_type_id, send_email) VALUES #{insert.join(',')}"
    end
  end

  def self.down
    remove_index :email_preferences, :customer_id
    delete_pref_type = EmailPreferenceType.find_by_form_tag('newsletters')
    if (delete_pref_type)
      execute "DELETE FROM email_preferences WHERE email_preference_type_id = #{delete_pref_type.id}"
      delete_pref_type.destroy
    end
  end
end

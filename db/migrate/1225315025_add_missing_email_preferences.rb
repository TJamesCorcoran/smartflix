class AddMissingEmailPreferences < ActiveRecord::Migration
  def self.up

    add_column :email_preferences, :created_at, :datetime, :null => false
    add_column :email_preferences, :updated_at, :datetime, :null => false

    # Partial customers before now have no email preferences.  
    # SmartFlix U customers have no email preferences.
    # Oops!  Double-Fail!
    # Fix that now.
    Customer.find(:all, :conditions =>"billing_address_id = 0").map do |customer|
      "(#{customer.id}, 1, 1)," +
      "(#{customer.id}, 2, 1)," +
      "(#{customer.id}, 3, 1)," +
      "(#{customer.id}, 4, 1)"
    end.in_groups_of(50, false) do |insert|
      execute "INSERT INTO email_preferences (customer_id, email_preference_type_id, send_email) VALUES #{insert.join(',')}"
    end

  end

  def self.down
    remove_column :email_preferences, :created_at, :datetime
    remove_column :email_preferences, :updated_at, :datetime


    Customer.find(:all, :conditions =>"billing_address_id = 0", :include => :email_preferences).each do |cust|
      cust.email_preferences.each { |pref| pref.destroy }
    end
  end
end

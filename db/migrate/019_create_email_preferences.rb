class CreateEmailPreferences < ActiveRecord::Migration
  def self.up
    create_table(:email_preferences, :primary_key => 'email_preference_id') do |t|
      t.column :customer_id, :integer, :null => false
      t.column :email_preference_type_id, :integer, :null => false
      t.column :send_email, :boolean, :null => false
    end
  end

  def self.down
    drop_table :email_preferences
  end
end

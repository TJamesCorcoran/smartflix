class TweakScheduledEmails < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE scheduled_emails CHANGE created_on created_at datetime AFTER email_type")
    add_column :scheduled_emails, :product_type, :string
    add_column :scheduled_emails, :updated_at, :datetime
  end

  def self.down
    execute("ALTER TABLE scheduled_emails CHANGE created_at created_on date AFTER customer_id")
    remove_column :scheduled_emails, :updated_at
    remove_column :scheduled_emails, :product_type
  end
end

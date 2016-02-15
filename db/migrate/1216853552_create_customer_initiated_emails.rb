class CreateCustomerInitiatedEmails < ActiveRecord::Migration
  def self.up
    create_table(:customer_initiated_emails, :primary_key => 'customer_initiated_email_id') do |t|
      t.integer :customer_id
      t.string :recipient_email
      t.integer :product_id
      t.text :message
      t.timestamps
    end
  end

  def self.down
    drop_table :customer_initiated_emails
  end
end

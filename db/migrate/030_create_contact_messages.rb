class CreateContactMessages < ActiveRecord::Migration
  def self.up
    create_table(:contact_messages, :primary_key => 'contact_message_id') do |t|
      t.column :name, :string, :null => false
      t.column :email, :string, :null => false
      t.column :message, :text, :null => false
      t.column :ip_address, :string, :null => false
      t.column :customer_id, :integer, :null => true
    end
  end

  def self.down
    drop_table :contact_messages
  end
end

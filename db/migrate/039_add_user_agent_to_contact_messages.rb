class AddUserAgentToContactMessages < ActiveRecord::Migration
  def self.up
    add_column(:contact_messages, :user_agent, :string, :null => false, :after => :ip_address)
  end

  def self.down
    remove_column(:contact_messages, :user_agent)
  end
end

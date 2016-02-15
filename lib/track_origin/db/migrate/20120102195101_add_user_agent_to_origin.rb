class AddUserAgentToOrigin < ActiveRecord::Migration
  def self.up
    add_column :origins, :user_agent, :string, :null=>true
  end

  def self.down
    remove_column :origins, :user_agent
  end
end

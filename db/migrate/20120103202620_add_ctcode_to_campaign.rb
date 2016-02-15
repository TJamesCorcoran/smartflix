class AddCtcodeToCampaign < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :ct_code , :string 
  end

  def self.down
    remove_column :campaigns, :ct_code
  end
end

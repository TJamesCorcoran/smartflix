class AddCampaignToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :ct_code, :string, :null => true
  end

  def self.down
    remove_column :orders, :ct_code
  end
end

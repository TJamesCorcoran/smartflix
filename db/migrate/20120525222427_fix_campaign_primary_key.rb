class FixCampaignPrimaryKey < ActiveRecord::Migration
  def self.up
    rename_column :campaigns, :campaign_id, :id
  end

  def self.down
    rename_column :campaigns, :id, :campaign_id
  end
end

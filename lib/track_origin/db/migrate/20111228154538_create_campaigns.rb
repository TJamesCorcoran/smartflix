class CreateCampaigns < ActiveRecord::Migration
  def self.up
    create_table "campaigns",  :primary_key => "id", :force => true do |t|
      t.string   "name",       :limit => 32, :default => "", :null => false

      t.date     "start_date", :null => false
      t.date     "end_date"

      t.decimal  "fixed_cost", :precision => 10, :scale => 2, :null => false, :default => 0.0
      t.decimal  "unit_cost",  :precision => 10, :scale => 2, :null => false, :default => 0.0

      t.string   "coupon",     :limit => 32
      t.string   "ct_code",    :limit => 32

      t.string   "contact_email"
      t.string   "notes"

      t.timestamps
    end
    
  end

  def self.down
    drop_table "campaigns"
  end
end

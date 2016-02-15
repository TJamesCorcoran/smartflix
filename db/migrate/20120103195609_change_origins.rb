class ChangeOrigins < ActiveRecord::Migration
  def self.up
    rename_column "origins", "origin_id", "id"
    add_column    "origins", "created_at", :datetime
    add_column    "origins", "ct_code", :string, :null => true
    execute("ALTER TABLE origins change  id    id integer      AUTO_INCREMENT")
    execute("ALTER TABLE origins change  ct_code    ct_code    varchar(255)  AFTER first_coupon")
    execute("ALTER TABLE origins change  created_at created_at datetime AFTER customer_id")

    execute("ALTER TABLE campaigns change  origin_id    id integer      AUTO_INCREMENT")
    rename_column "campaigns", "campaign_name", "name"
  end

  def self.down
    rename_column    "origins", "id", "origin_id"
    remove_column    "origins", "created_at"
    remove_column    "origins", "ct_code"

    execute("ALTER TABLE campaigns change  id    origin_id integer      AUTO_INCREMENT")
    rename_column "campaigns", "name", "campaign_name"
  end
end

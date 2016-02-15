class FixCampaignsTableToMatchHi < ActiveRecord::Migration
  def self.up
    execute "update campaigns set id = 8 where id = 0"
    execute "ALTER TABLE campaigns CHANGE id id  integer NOT NULL AUTO_INCREMENT"
    execute "ALTER TABLE campaigns CHANGE fixed_cost fixed_cost  decimal(10,2) NOT NULL"
    execute "ALTER TABLE campaigns CHANGE unit_cost unit_cost  decimal(10,2) NOT NULL"
    execute "ALTER TABLE campaigns CHANGE ct_code ct_code varchar(32) AFTER coupon"
    execute "ALTER TABLE campaigns CHANGE initial_uri_regexp initial_uri_regexp varchar(32) AFTER cat_id"
  end

  def self.down
    execute "ALTER TABLE campaigns CHANGE id id  integer NOT NULL"
    execute "ALTER TABLE campaigns CHANGE fixed_cost fixed_cost  decimal(10,2)"
    execute "ALTER TABLE campaigns CHANGE unit_cost unit_cost  decimal(10,2)"
    execute "ALTER TABLE campaigns CHANGE ct_code ct_code varchar(32) AFTER updated_at"
    execute "ALTER TABLE campaigns CHANGE initial_uri_regexp initial_uri_regexp varchar(32) AFTER cat_id"

    execute "update campaigns set id = 0 where id = 8"
  end
end

class CreateOrigins < ActiveRecord::Migration
  def self.up
    create_table :origins do |t|
      t.string  :referer,    :first_uri, :first_coupon, :ct_code, :null => true
      t.integer :session_id, :customer_id, :null => true
      t.timestamps 
    end

    add_index "origins", ["customer_id"], :name => "index_origins_on_customer_id"
    add_index "origins", ["session_id"],  :name => "index_origins_on_session_id"

  end

  def self.down
    drop_table :origins
  end
end

class CreateOrigins < ActiveRecord::Migration
  def self.up
    create_table(:origins, :primary_key => 'origin_id') do |t|
      t.column :referer, :string, :null => true
      t.column :first_uri, :string, :null => true
      t.column :first_coupon, :string, :null => true
      t.column :session_id, :integer, :null => true
      t.column :customer_id, :integer, :null => true
    end
    add_index :origins, :session_id
  end

  def self.down
    drop_table :origins
  end
end

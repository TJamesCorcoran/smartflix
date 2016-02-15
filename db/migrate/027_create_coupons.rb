class CreateCoupons < ActiveRecord::Migration
  def self.up
    create_table(:coupons, :primary_key => 'coupon_id') do |t|
      t.column :code, :string, :null => false
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :start_date, :date, :null => false
      t.column :end_date, :date, :null => false
      t.column :new_customers_only, :boolean, :null => false, :default => false
      t.column :single_use_only, :boolean, :null => false, :default => false
      t.column :active, :boolean, :null => false, :default => true
      t.column :created_at, :datetime, :null => false
    end
    add_index :coupons, :code
  end

  def self.down
    drop_table :coupons
  end
end

class CreatePostageChart < ActiveRecord::Migration
  def self.up
    create_table (:usps_postage_charts) do |t|
      t.column :usps_physical, :string,  :null => false
      t.column :usps_class,    :string,  :null => false
      t.column :weight_oz,     :int,     :null => false
      t.column :price_cents,   :int,     :null => false
    end

    execute "insert into usps_postage_charts (usps_physical, usps_class, weight_oz, price_cents) values  ('flat', 'first', 1, 80), ('flat', 'first', 2, 97),  ('flat', 'first', 3, 114),  ('flat', 'first', 4, 131),  ('flat', 'first', 5, 148),  ('flat', 'first', 6, 165), ('flat', 'first', 7, 182), ('flat', 'first', 8, 199), ('flat', 'first', 9, 216), ('flat', 'first', 10, 233), ('flat', 'first', 11, 250), ('flat', 'first', 12, 267), ('flat', 'first', 13, 284)"
    
  end
  def self.down
    drop_table :usps_postage_charts
  end
end

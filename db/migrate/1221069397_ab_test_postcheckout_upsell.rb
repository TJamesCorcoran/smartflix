class AbTestPostcheckoutUpsell < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:postcheckout_upsell,     6, 0.0, [:true, :false])
    add_column :orders, :postcheckout_sale, :boolean, :default => false,  :null => false

    create_table(:upsell_offers, :primary_key => 'upsell_offer_id') do |t|
      t.column :customer_id,     :integer, :null => false
      t.column :reco_type,       :string,  :null => false
      t.column :reco_id,         :integer, :null => false
      t.column :base_order_id,   :integer, :null => false
      t.column :upsell_order_id, :integer
      t.column :ordinal,         :integer, :null => false
      t.timestamps
    end

    add_column :universities, :category_id, :integer, :default => false,  :null => false

    University.find_by_name("Woodturner University").andand.update_attributes(:category_id => 28) 
    University.find_by_name("Airbrush University").andand.update_attributes(:category_id => 126) 
    University.find_by_name("Glasswork University").andand.update_attributes(:category_id => 7) 
    University.find_by_name("Jewelry Making University").andand.update_attributes(:category_id => 42) 
    University.find_by_name("Oil Painting University").andand.update_attributes(:category_id => 87) 
    University.find_by_name("Pastel University").andand.update_attributes(:category_id => 162) 
    University.find_by_name("Watercolor University").andand.update_attributes(:category_id => 159) 
    University.find_by_name("Welder University").andand.update_attributes(:category_id => 27) 
    University.find_by_name("Woodcarving University").andand.update_attributes(:category_id => 97) 

  end

  def self.down
    AbTest.find_by_name("PostcheckoutUpsell").andand.destroy_self_and_children([:ab_test_options, :ab_test_results])
    remove_column :orders, :postcheckout_sale
    drop_table :upsell_offers

    remove_column :universities, :category_id
  end
end

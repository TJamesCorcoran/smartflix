class TweaksToMergeFixtures < ActiveRecord::Migration
  def self.up
    add_column :line_items, :shipment_id, :integer
    add_column :line_items, :uncancelledP, :bool, :null=>false ,:default =>1
    add_column :line_items, :copy_id, :integer
    add_column :line_items, :lateMsg1Sent, :date
    add_column :line_items, :lateMsg2Sent, :date
    add_column :line_items, :created_at, :datetime
    add_column :line_items, :updated_at, :datetime
    add_column :line_items, :dateBack, :date
    add_column :orders, :orderDate, :date
    add_column :product_sets, :order_matters, :boolean, :null => false, :default => 0
    add_column :products, :vendor_id, :integer, :null => false
    add_index  :products, :vendor_id
    add_column :products, :virtual, :boolean, :null => false, :default => 0
    add_column :customers, :emailBouncedP, :bool, :null => false, :default =>0
    add_column :customers, :throttleP, :bool, :null => false, :default =>0
    add_column :customers, :notes, :string
    
    create_table(:abandoned_basket_emails, :primary_key => 'tabe_id') do |t|
      t.column :customer_id, :integer, :null => false
      t.column :date_sent, :date, :null => false
    end
    
    create_table(:inventory_ordereds, :primary_key => 'product_id') do |t|
      t.column :quantDvd, :integer
    end
    
    create_table( :purchasers, :primary_key => 'id' ) do |t|
      t.column :email, :string 
      t.column :name_first, :string
      t.column :name_last, :string
      t.column :addr_1, :string 
      t.column :addr_2, :string 
      t.column :city, :string 
      t.column :state, :string 
      t.column :zip, :string 
      t.column :activeP, :boolean, :default => true
      t.column :notes, :string 
    end
    
    create_table( :death_logs, :primary_key => 'deathLogID' ) do |t|
      t.column :newDeathType, :integer 
      t.column :editDate, :date
      t.column :note_last, :string
      t.column :copy_id, :integer 
    end
    
    create_table( :scheduled_emails, :primary_key => 'scheduled_email_id' ) do |t|
      t.column :customer_id, :integer 
      t.column :created_on, :date
      t.column :product_id, :integer
      t.column :email_type, :string 
    end
    
    create_table( :vendor_moods, :primary_key => 'vendor_mood_id' ) do |t|
      t.column :moodText, :string 
    end
    create_table(:campaigns_sent_to_customers, :primary_key => 'campaigns_sent_to_customers_id') do |t|
      t.column :customerID, :integer, :null => false
      t.column :email_campaign_id, :integer, :null => false
      t.column :created_at, :datetime
    end
    
    create_table(:vendor_order_logs, :primary_key => 'vendor_order_log_id') do |t|
      t.column :product_id, :integer, :null => false
      t.column :orderDate, :date, :null => false
      t.column :quant, :integer, :null => false
      t.column :purchaser_id, :integer
    end
    
    create_table(:magazines, :primary_key => 'magazine_id') do |t|
      t.column :title,        :string,    :null => false
      t.column :street,       :string
      t.column :city,         :string
      t.column :state,        :string
      t.column :zip,          :string
      t.column :phone,        :string
      t.column :fax,          :string
      t.column :cat_code,     :string
      t.column :catID,        :integer
      t.column :circ,         :integer
      t.column :schedule,     :string
      t.column :readers,      :string
      t.column :editor,       :string
      t.column :url,          :string
      t.column :email,        :string
    end
    
    create_table(:magazine_cats, :primary_key => 'magazine_cat_id') do |t|
      t.column :string_code,           :string,    :null => false
      t.column :name,                  :string,    :null => false
      t.column :smartflix_cat_id,      :integer
    end
    
    create_table(:campaigns_sent_to_magazines, :primary_key => 'campaigns_sent_to_magazines_id') do |t|
      t.column :magazine_id,             :integer,    :null => false
      t.column :email_campaign_id,             :integer,    :null => false
      t.column :created_at,              :datetime
    end
    
    create_table(:vendors, :primary_key => 'vendor_id') do |t|
      t.column :name,             :string,    :null => false
      t.column :vendor_mood_id,             :integer,    :null => false
      t.column :outOfBusinessP,              :boolean, :null => false
      t.column :notes,              :string
      t.column :emailAddr,              :string
      t.column :advertiseP,              :boolean, :null => false, :default => 1
    end

  end
  
  def self.down
    remove_column :line_items, :dateBack
    remove_column :line_items, :created_at
    remove_column :line_items, :updated_at
    remove_column :line_items, :lateMsg1Sent
    remove_column :line_items, :lateMsg2Sent
    remove_column :line_items, :copy_id
    remove_column :line_items, :uncancelledP
    remove_column :line_items, :shipment_id
    remove_column :customers, :emailBouncedP
    remove_column :customers, :throttleP
    remove_column :customers, :notes
    remove_column :orders, :orderDate
    remove_column :product_sets, :order_matters
    remove_column :products, :vendor_id
    remove_column :products, :virtual
    
    drop_table :abandoned_basket_emails
    drop_table :inventory_ordereds
    drop_table :purchasers
    drop_table :death_logs
    drop_table :scheduled_emails
    drop_table :vendor_moods
    drop_table :campaigns_sent_to_customers
    drop_table :vendor_order_logs
    drop_table :magazines
    drop_table :magazine_cats
    drop_table :campaigns_sent_to_magazines
    drop_table :vendors
    
  end
end

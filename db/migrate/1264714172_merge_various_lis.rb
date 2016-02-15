class MergeVariousLis < ActiveRecord::Migration
  def self.up

    remove_column :categories_products, :category_product_id
    add_column     :line_items, :apologyCopyP, :boolean 
    add_column     :line_items, :overdueGraceGranted, :integer, :default => 0
    add_column     :line_items, :wrongItemSent, :boolean , :default => 0
    add_column     :line_items, :copy_id_intended, :integer 
    add_column     :line_items, :return_email_sent, :boolean
    add_column     :line_items, :lateMsg3Sent, :date 
    add_column     :line_items, :refunded, :boolean
    add_column     :line_items, :ignore_for_univ_limits, :boolean
    add_column     :orders, :unshippedMsgSentP, :boolean
    add_column     :orders, :replacesShipment, :integer
    add_column     :orders, :prereqMsgSentP, :integer
    
    add_column     :products, :part_number, :string
    add_column     :products, :in_print, :boolean
    
    add_index    :line_items, :product_id
    add_index    :line_items, :shipment_id
    add_index    :line_items, :copy_id
    add_index    :line_items, :dateBack
    
    drop_table :url_tracks
    
    create_table(:url_tracks, :primary_key => 'url_track_id') do |t|
      t.column :session_id,      :string,  :null => false
      t.column :customer_id,     :integer
      t.column :path,            :string,  :null => false
      t.column :controller,      :string,  :null => false
      t.column :action,          :string,  :null => false
      t.column :action_id,       :string
      t.column :created_at,      :datetime, :null => false
    end
    
    add_index    :url_tracks, :customer_id
    add_index    :url_tracks, :controller
    add_index    :url_tracks, :action
    add_index    :url_tracks, :action_id
    add_index    :url_tracks, :session_id
    
    
    create_table(:product_delays) do |t|
      t.column :product_id,      :integer,  :null => false
      t.column :ordinal,         :integer,  :null => false
      t.column :days_delay,      :integer,  :null => false
      t.timestamps
    end
    
    
    add_index    :line_items, :uncancelledP
    add_index    :line_items, :actionable
    
    add_column     :featured_products, :created_at, :datetime
    add_column     :featured_products, :updated_at, :datetime
    drop_table :line_item_auxes                              
    drop_table :line_item_status_codes                        
    drop_table :line_item_statuses                            
    
    change_column :vendor_order_logs, :quant, :integer, :default => 0, :null => false    
    
    change_column :copies, :mediaformat, :integer    , :default => 2, :null => false
    change_column :copies, :status,            :integer, :default => 1, :null => false
    change_column :copies, :inStock,           :integer, :default => 1, :null => false
    change_column :copies, :tmpReserve,        :integer, :default => 0, :null => false
    change_column :copies, :visibleToShipperP, :bool,    :default => 0, :null => false
    change_column :copies, :payPerRentP,       :bool,    :default => 0, :null => false
    
    change_column :products, :display,       :bool, :null => false, :default => 1
    
    create_table "dvd_weights", :force => true do |t|
      t.boolean "boxP",      :null => false
      t.integer "num_dvds",  :null => false
      t.integer "weight_oz", :null => false
    end
    
  end
  
  
  def self.down
    
    drop_table :product_delays
    
    remove_column     :line_items, :apologyCopyP         
    remove_column     :line_items, :overdueGraceGranted  
    remove_column     :line_items, :wrongItemSent        
    remove_column     :line_items, :copy_id_intended     
    remove_column     :line_items, :return_email_sent    
    remove_column     :line_items, :lateMsg3Sent         
    remove_column     :line_items, :refunded             
    remove_column     :line_items, :ignore_for_univ_limits 
    
    
    remove_column     :orders, :unshippedMsgSentP
    remove_column     :orders, :replacesShipment
    remove_column     :orders, :prereqMsgSentP
    remove_column     :products, :part_number
    remove_column     :products, :in_print
    remove_index    :line_items, :product_id
    remove_index    :line_items, :shipment_id
    remove_index    :line_items, :copy_id
    remove_index    :line_items, :dateBack
    
    
    remove_index    :url_tracks, :customer_id
    remove_index    :url_tracks, :session_id
    remove_index    :url_tracks, :action_id
    
    remove_index    :scheduled_emails, :product_id
    
    
    remove_index    :line_items, :uncancelledP
    remove_index    :line_items, :actionable
    
    remove_column     :featured_products, :created_at
    remove_column     :featured_products, :updated_at
    
    create_table "line_item_auxes", :force => true do |t|
      t.integer  "line_item_id",                              :null => false
      t.integer  "format",                 :default => 2,     :null => false
      t.integer  "shipment_id"
      t.integer  "copy_id"
      t.date     "dateBack"
      t.boolean  "uncancelledP",           :default => true,  :null => false
      t.boolean  "apologyCopyP"
      t.date     "lateMsg1Sent"
      t.date     "lateMsg2Sent"
      t.integer  "overdueGraceGranted",    :default => 0
      t.boolean  "wrongItemSent",          :default => false, :null => false
      t.integer  "ZcLineItemID"
      t.integer  "copy_id_intended"
      t.boolean  "return_email_sent",      :default => false, :null => false
      t.date     "lateMsg3Sent"
      t.boolean  "refunded",               :default => false, :null => false
      t.datetime "created_at"
      t.datetime "tvr_master_updated_at"
      t.boolean  "ignore_for_univ_limits", :default => false, :null => false
    end
    
    add_index "line_item_auxes", ["shipment_id"], :name => "index_line_item_auxes_on_shipment_id"
    add_index "line_item_auxes", ["copy_id"], :name => "index_line_item_auxes_on_copy_id"
    add_index "line_item_auxes", ["dateBack"], :name => "index_line_item_auxes_on_dateBack"
    
    create_table "line_item_status_codes", :primary_key => "line_item_status_code_id", :force => true do |t|
      t.string "name", :null => false
    end
    
    create_table "line_item_statuses", :primary_key => "line_item_status_id", :force => true do |t|
      t.integer "line_item_id",                            :null => false
      t.integer "line_item_status_code_id",                :null => false
      t.date    "shipment_date"
      t.date    "early_arrival_date"
      t.date    "late_arrival_date"
      t.integer "place_in_line"
      t.integer "days_delay",               :default => 0
    end
    
    change_column :vendor_order_logs, :quant, :integer
    
    change_column :copies, :mediaformat, :integer
    change_column :copies, :status,            :integer
    change_column :copies, :inStock,           :integer
    change_column :copies, :tmpReserve,        :integer
    change_column :copies, :visibleToShipperP, :bool
    change_column :copies, :payPerRentP,       :bool
    change_column :products, :display,       :bool, :null => false, :default => 0
    
    drop_table "dvd_weights"

    add_column :categories_products, :category_product_id, :integer, :null => false
  end
  
end

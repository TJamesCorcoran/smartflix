class MergeBackendToFrontend < ActiveRecord::Migration
  def self.up
    
    create_table "hi_to_sf_transfers", :primary_key => "hi_to_sf_transfers_id", :force => true do |t|
      t.float    "dollars"
      t.string   "memo"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    
    
    create_table "adwords_ads", :force => true do |t|
      t.string   "headline",                           :null => false
      t.string   "destinationUrl",                     :null => false
      t.string   "description1",                       :null => false
      t.string   "description2",                       :null => false
      t.string   "displayUrl",                         :null => false
      t.integer  "adwords_group_id",                   :null => false
      t.string   "status",                             :null => false
      t.string   "adType",                             :null => false
      t.integer  "thing_advertised_id",                :null => false
      t.string   "thing_advertised_type",              :null => false
      t.integer  "google_id",             :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "adwords_authors", :primary_key => "authorID", :force => true do |t|
      t.string "alternateText", :limit => 100
    end
    
    create_table "adwords_campaigns", :force => true do |t|
      t.string   "name",                      :null => false
      t.float    "daily_budget",              :null => false
      t.string   "status",                    :null => false
      t.integer  "google_id",    :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "removed_at"
      t.datetime "updated_at"
    end
    
    create_table "adwords_groups", :force => true do |t|
      t.string   "name",                       :null => false
      t.integer  "keywordMaxCpc",              :null => false
      t.integer  "campaign_id",                :null => false
      t.integer  "google_id",     :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "adwords_keywords", :force => true do |t|
      t.string   "text",                          :null => false
      t.boolean  "paused",                        :null => false
      t.integer  "adwords_group_id",              :null => false
      t.integer  "google_id",        :limit => 8, :null => false
      t.datetime "created_at"
      t.datetime "removed_at"
      t.datetime "updated_at"
    end
    
    create_table "author_interaction_kinds", :primary_key => "author_interaction_kind_id", :force => true do |t|
      t.text "kind", :null => false
    end
    
    
    create_table "author_interactions", :primary_key => "author_interaction_id", :force => true do |t|
      t.date    "interaction_date",                          :null => false
      t.integer "author_id",                  :default => 0, :null => false
      t.integer "author_interaction_kind_id", :default => 0, :null => false
      t.text    "url"
    end
    
    create_table "campaigns", :primary_key => "campaign_id", :force => true do |t|
      t.string   "campaign_name",      :limit => 32,                                :default => "", :null => false
      t.date     "start_date",                                                                      :null => false
      t.date     "end_date"
      t.decimal  "fixed_cost",                       :precision => 10, :scale => 2
      t.decimal  "unit_cost",                        :precision => 10, :scale => 2
      t.string   "coupon",             :limit => 32
      t.string   "initial_uri_regexp", :limit => 32
      t.string   "contact_email"
      t.string   "notes"
      t.integer  "cat_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    add_index "campaigns", ["cat_id"], :name => "index_campaigns_on_cat_id"
    
    create_table "categories_dropins", :primary_key => "ID", :force => true do |t|
      t.integer "catID",              :default => 0, :null => false
      t.integer "dropinLiteratureID", :default => 0, :null => false
    end
    
    create_table "categories_products", :primary_key => "category_product_id", :force => true do |t|
      t.integer "product_id",  :null => false
      t.integer "category_id", :null => false
    end
    
    add_index "categories_products", ["product_id"], :name => "titleID"
    add_index "categories_products", ["category_id"], :name => "catID"
    
    
    
    create_table "chargeback_disputes", :primary_key => 'id', :force => true do |t|
      t.string   "order_id",     :null => false
      t.datetime "created_at",   :null => false
      t.datetime "updated_at",   :null => false
      t.integer  "hr_person_id", :null => false
    end
    
    create_table "cobrand_payments", :primary_key => 'id', :force => true do |t|
      t.integer "cobrand_id"
      t.date    "created_at"
      t.float   "payment"
    end
    
    create_table "dvd_weights", :primary_key => 'id', :force => true do |t|
      t.boolean "boxP",      :null => false
      t.integer "num_dvds",  :null => false
      t.integer "weight_oz", :null => false
    end
    
    create_table "ebay_auctions", :primary_key => "ebay_auctions_id", :force => true do |t|
      t.text    "email_addr",                                                       :null => false
      t.text    "ebay_item_id",                                                     :null => false
      t.text    "ebay_user_id"
      t.decimal "amount_paid",       :precision => 4, :scale => 2, :default => 0.0, :null => false
      t.text    "coupon_code"
      t.integer "category_id",                                                      :null => false
      t.date    "auction_date"
      t.date    "coupon_issue_date"
      t.decimal "cost",              :precision => 9, :scale => 2
      t.integer "title_id"
    end
    
    # add_index "ebay_auctions", ["email_addr"], :name => "index_email_addr_on_ebay_coupon_sales"
    # add_index "ebay_auctions", ["coupon_code"], :name => "index_coupon_code_on_ebay_coupon_sales"
    # add_index "ebay_auctions", ["title_id"], :name => "index_ebay_auctions_on_title_id"
    # add_index "ebay_auctions", ["category_id"], :name => "index_ebay_auctions_on_cat_id"
    
    
    create_table "gnucash", :id => false, :force => true do |t|
      t.date    "date",                                                  :null => false
      t.string  "type",     :limit => 64
      t.string  "category", :limit => 64
      t.decimal "amount",                 :precision => 10, :scale => 2
    end
    
    add_index "gnucash", ["date"], :name => "date"
    
    create_table "gracePeriodEditLog", :primary_key => "gracePeriodEditLogID", :force => true do |t|
      t.integer "lineItemID",              :default => 0, :null => false
      t.date    "editDate",                               :null => false
      t.integer "newSetting", :limit => 1, :default => 0, :null => false
    end
    
    create_table "hi_to_sf_transfers", :primary_key => "hi_to_sf_transfers_id", :force => true do |t|
      t.float    "dollars"
      t.string   "memo"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "hr_payrates", :primary_key => "hr_payrate_id", :force => true do |t|
      t.decimal "rate", :precision => 4, :scale => 2, :default => 0.0, :null => false
    end
    
    create_table "hr_person_payrates", :primary_key => "hr_person_payrate_id", :force => true do |t|
      t.integer "hr_person_id",  :default => 0, :null => false
      t.integer "hr_payrate_id", :default => 0, :null => false
    end
    
    create_table "inventories", :primary_key => "inventoryID", :force => true do |t|
      t.date    "inventoryDate",                :null => false
      t.integer "startID",       :default => 0, :null => false
      t.integer "endID",         :default => 0, :null => false
      t.integer "copyCount",     :default => 0, :null => false
      t.integer "misfiledCount", :default => 0, :null => false
      t.integer "missingCount",  :default => 0, :null => false
      t.integer "foundCount",    :default => 0, :null => false
      t.integer "returnedCount", :default => 0, :null => false
    end
    
    add_index "inventories", ["inventoryDate"], :name => "index_inventory_on_inventoryDate"
    
    create_table "inventory_ordereds", :primary_key => "product_id", :force => true do |t|
      t.integer "quantDvd", :default => 0
    end
    
    create_table "lateMessages", :primary_key => "lateMessageID", :force => true do |t|
      t.integer "customerID", :default => 0, :null => false
      t.text    "message"
    end
    
    
    
    create_table "line_item_problem_types", :primary_key => "line_item_problem_type_id", :force => true do |t|
      t.string "form_tag", :default => "", :null => false
    end
    
    create_table "line_item_problems", :primary_key => "line_item_problem_id", :force => true do |t|
      t.integer "line_item_id",              :default => 0,     :null => false
      t.integer "line_item_problem_type_id", :default => 0,     :null => false
      t.integer "wrong_copy_id"
      t.string  "details"
      t.integer "replacement_order_id"
      t.boolean "noted",                     :default => false, :null => false
    end
    
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
    
    create_table "order_univ_dvd_rate_updates", :primary_key => "order_univ_dvd_rate_updates_id", :force => true do |t|
      t.integer  "univ_dvd_rate"
      t.string   "reference_type"
      t.integer  "reference_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "other_ads", :primary_key => 'id', :force => true do |t|
      t.boolean "advertiseP"
      t.text    "headline",                                    :null => false
      t.text    "base_url",                                    :null => false
      t.text    "line_1",                                      :null => false
      t.text    "line_2",                                      :null => false
      t.text    "keywords",                                    :null => false
      t.decimal "maxCPC",        :precision => 6, :scale => 2, :null => false
      t.integer "university_id"
    end
    
    add_index "other_ads", ["university_id"], :name => "index_other_ads_on_university_id"
    
    create_table "pageranks", :primary_key => 'id', :force => true do |t|
      t.date  "date",                        :null => false
      t.float "rank",       :default => 0.0, :null => false
      t.text  "searchterm"
    end
    
    create_table "payPerRentPayments", :primary_key => "payPerRent_payments_id", :force => true do |t|
      t.date    "datePaid",                                                :null => false
      t.integer "vendorID",                               :default => 0,   :null => false
      t.decimal "amount",   :precision => 4, :scale => 2, :default => 0.0, :null => false
    end
    
    create_table "people", :primary_key => "person_id", :force => true do |t|
      t.string  "name_first",                  :default => "",    :null => false
      t.string  "name_last",                   :default => "",    :null => false
      t.boolean "employeeP",                   :default => false, :null => false
      t.boolean "hourlyP",                     :default => false, :null => false
      t.string  "shirt_size"
      t.date    "start_date",                                     :null => false
      t.date    "end_date"
      t.string  "fob_string"
      t.string  "phonenum"
      t.boolean "authority_newsletter"
      t.boolean "authority_edit_copy"
      t.boolean "authority_finance"
      t.boolean "authority_usps_form"
      t.boolean "authority_chargeback"
      t.boolean "authority_timesheet"
      t.string  "oneway_hash_of_password"
      t.integer "employee_number"
      t.string  "emailaddr",                                      :null => false
      t.boolean "email_finance",               :default => false, :null => false
      t.boolean "email_garbage",               :default => false, :null => false
      t.boolean "email_purchasing",            :default => false, :null => false
      t.boolean "email_custsupport_sf",        :default => false, :null => false
      t.boolean "email_custsupport_hi",        :default => false, :null => false
      t.boolean "email_marketing_sf",          :default => false, :null => false
      t.boolean "email_marketing_hi",          :default => false, :null => false
      t.boolean "authority_destroy_copy",      :default => false, :null => false
      t.boolean "authority_edit_order",        :default => false, :null => false
      t.boolean "email_polishing",             :default => false, :null => false
      t.boolean "email_marketing_sf_intern",   :default => false, :null => false
      t.boolean "authority_refund_cc",         :default => false, :null => false
      t.boolean "authority_cancel_univ_order", :default => false, :null => false
      t.float   "hi_time_fraction",            :default => 0.0
      t.float   "hi_billing",                  :default => 12.0
    end
    
    create_table "potential_items", :force => true do |t|
      t.integer "potential_shipment_id", :null => false
      t.integer "copy_id"
      t.integer "gift_cert_id"
      t.string  "type"
      t.integer "line_item_id",          :null => false
    end
    
    add_index "potential_items", ["copy_id"], :name => "index_potential_items_on_copy_id"
    add_index "potential_items", ["gift_cert_id"], :name => "index_potential_items_on_gift_cert_id"
    
    create_table "potential_shipments", :force => true do |t|
      t.integer "customer_id", :null => false
      t.text    "barcode",     :null => false
    end
    
    
    create_table "purchasers", :primary_key => 'id', :force => true do |t|
      t.string  "email"
      t.string  "name_first"
      t.string  "name_last"
      t.string  "addr_1"
      t.string  "addr_2"
      t.string  "city"
      t.string  "state"
      t.string  "zip"
      t.boolean "activeP",    :default => true
      t.string  "notes"
    end
    
    create_table "scheduled_emails", :primary_key => "scheduled_email_id", :force => true do |t|
      t.integer "customer_id"
      t.date    "created_on"
      t.integer "product_id"
      t.string  "email_type",  :default => "recommendation"
    end
    
    add_index    :scheduled_emails, :customer_id
    add_index    :scheduled_emails, :product_id

    create_table "timesheet_items", :primary_key => "hr_timesheet_items_id", :force => true do |t|
      t.integer  "hr_person_id",                                    :default => 0,                     :null => false
      t.date     "date",                                                                               :null => false
      t.time     "begin",                                           :default => '2000-01-01 00:00:00', :null => false
      t.time     "end",                                             :default => '2000-01-01 00:00:00', :null => false
      t.decimal  "percent_smartflix", :precision => 3, :scale => 2, :default => 0.0,                   :null => false
      t.integer  "payrate",                                         :default => 0,                     :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "tobuys", :primary_key => "tobuy_id", :force => true do |t|
      t.integer  "product_id", :null => false
      t.integer  "quant"
      t.integer  "pain"
      t.datetime "updated_at"
    end
    
    create_table "tvr_interview_emails", :primary_key => "tie_id", :force => true do |t|
      t.integer "cust_id",          :default => 0, :null => false
      t.date    "date_sent",                       :null => false
      t.date    "date_interviewed"
      t.date    "date_blogged"
    end
    
    
    create_table "tvr_onetimer_emails", :id => false, :force => true do |t|
      t.integer "toeID",                     :null => false
      t.integer "customerID", :default => 0, :null => false
      t.date    "dateSent",                  :null => false
    end
    
    add_index "tvr_onetimer_emails", ["toeID"], :name => "toeID"
    
    create_table "univ_inventory_infos", :primary_key => "univ_inventory_info_id", :force => true do |t|
      t.integer  "university_id",      :null => false
      t.integer  "shortfall_today",    :null => false
      t.integer  "shortfall_one_week", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "usps_postage_charts", :primary_key => 'id', :force => true do |t|
      t.text    "usps_physical"
      t.string  "usps_class",      :null => false
      t.integer "weight_oz",       :null => false
      t.integer "price_cents",     :null => false
      t.integer "zone"
      t.date    "rate_start_date", :null => false
      t.date    "rate_end_date",   :null => false
    end
    
    create_table "usps_postage_forms", :primary_key => 'id', :force => true do |t|
      t.string   "form_name",  :null => false
      t.datetime "created_at", :null => false
      t.integer  "person_id",  :null => false
    end
    
    rename_column :death_logs, :note_last, :note
    
    
    # ------------------------------ snip! ------------------------------
  end
  
  
  def self.down
    drop_table  "adwords_ads"
    drop_table  "adwords_authors"
    drop_table  "adwords_campaigns"
    drop_table  "adwords_groups"
    drop_table  "adwords_keywords"
    drop_table  "author_interaction_kinds"
    drop_table  "author_interactions"
    drop_table  "campaigns"
    drop_table  "categories_dropins"
    drop_table  "categories_products"
    drop_table  "chargeback_disputes"
    drop_table  "cobrand_payments"
    drop_table  "dvd_weights"
    drop_table  "ebay_auctions"
    drop_table  "gnucash"
    drop_table  "gracePeriodEditLog"
    drop_table  "hi_to_sf_transfers"
    drop_table  "hr_payrates"
    drop_table  "hr_person_payrates"
    drop_table  "inventories"
    drop_table  "inventory_ordereds"
    drop_table  "lateMessages"
    drop_table  "line_item_problem_types"
    drop_table  "line_item_problems"
    drop_table  "line_item_status_codes"
    drop_table  "line_item_statuses"
    drop_table  "order_univ_dvd_rate_updates"
    drop_table  "other_ads"
    drop_table  "pageranks"
    drop_table  "payPerRentPayments"
    drop_table  "people"
    drop_table  "potential_items"
    drop_table  "potential_shipments"
    drop_table  "purchasers"
    drop_table  "scheduled_emails"
    drop_table  "timesheet_items"
    drop_table  "tobuys"
    drop_table  "tvr_interview_emails"
    drop_table  "tvr_onetimer_emails"
    drop_table  "univ_inventory_infos"
    drop_table  "usps_postage_charts"
    drop_table  "usps_postage_forms"
    
    rename_column :death_logs, :note, :note_last
  end
end

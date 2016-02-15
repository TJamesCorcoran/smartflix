# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131114213016) do

  create_table "ab_test_options", :primary_key => "ab_test_option_id", :force => true do |t|
    t.integer  "ab_test_id", :default => 0,  :null => false
    t.string   "name",       :default => "", :null => false
    t.integer  "ordinal",    :default => 0,  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "ab_test_options", ["ab_test_id"], :name => "index_ab_test_options_on_ab_test_id"

  create_table "ab_test_results", :primary_key => "ab_test_result_id", :force => true do |t|
    t.integer  "ab_test_visitor_id", :default => 0,  :null => false
    t.integer  "ab_test_id",         :default => 0,  :null => false
    t.integer  "ab_test_option_id",  :default => 0,  :null => false
    t.string   "value",              :default => "", :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "reference_id"
    t.datetime "created_at",                         :null => false
    t.string   "reference_type"
  end

  add_index "ab_test_results", ["ab_test_id"], :name => "index_ab_test_results_on_ab_test_id"
  add_index "ab_test_results", ["ab_test_visitor_id"], :name => "index_ab_test_results_on_ab_test_visitor_id"
  add_index "ab_test_results", ["reference_id"], :name => "index_ab_test_results_on_order_id"

  create_table "ab_test_visitors", :primary_key => "ab_test_visitor_id", :force => true do |t|
    t.integer  "customer_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "ab_test_visitors", ["customer_id"], :name => "index_ab_test_visitors_on_customer_id"

  create_table "ab_tests", :primary_key => "ab_test_id", :force => true do |t|
    t.boolean  "active",      :default => true, :null => false
    t.string   "name",        :default => "",   :null => false
    t.integer  "ordinal",     :default => 0,    :null => false
    t.integer  "spacing",     :default => 0,    :null => false
    t.string   "result_type", :default => "",   :null => false
    t.string   "base_result", :default => "",   :null => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "ab_tests", ["name"], :name => "index_ab_tests_on_name", :unique => true

  create_table "abandoned_basket_emails", :primary_key => "tabe_id", :force => true do |t|
    t.integer "customer_id", :null => false
    t.date    "date_sent",   :null => false
  end

  create_table "account_credit_transactions", :primary_key => "account_credit_transaction_id", :force => true do |t|
    t.integer  "account_credit_id",                                 :default => 0,   :null => false
    t.decimal  "amount",              :precision => 9, :scale => 2, :default => 0.0
    t.integer  "gift_certificate_id"
    t.integer  "payment_id"
    t.string   "transaction_type",                                  :default => "",  :null => false
    t.datetime "created_at",                                                         :null => false
    t.integer  "univ_months",                                       :default => 0
  end

  create_table "account_credits", :primary_key => "account_credit_id", :force => true do |t|
    t.integer "customer_id",                               :default => 0,   :null => false
    t.decimal "amount",      :precision => 9, :scale => 2, :default => 0.0, :null => false
    t.integer "univ_months",                               :default => 0,   :null => false
  end

  add_index "account_credits", ["customer_id"], :name => "index_account_credits_on_customer_id"

  create_table "addresses", :primary_key => "address_id", :force => true do |t|
    t.string   "first_name", :default => "", :null => false
    t.string   "last_name",  :default => "", :null => false
    t.string   "address_1",  :default => "", :null => false
    t.string   "address_2",  :default => "", :null => false
    t.string   "city",       :default => "", :null => false
    t.integer  "state_id",   :default => 0,  :null => false
    t.string   "postcode",   :default => "", :null => false
    t.integer  "country_id", :default => 0,  :null => false
    t.string   "type",       :default => "", :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "adwords_ads", :primary_key => "adwords_ad_id", :force => true do |t|
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

  create_table "adwords_campaigns", :primary_key => "adwords_campaign_id", :force => true do |t|
    t.string   "name",                      :null => false
    t.float    "daily_budget",              :null => false
    t.string   "status",                    :null => false
    t.integer  "google_id",    :limit => 8, :null => false
    t.datetime "created_at"
    t.datetime "removed_at"
    t.datetime "updated_at"
  end

  create_table "adwords_categories", :primary_key => "adwords_category_id", :force => true do |t|
    t.string "alternate_text"
    t.string "additional_keywords"
  end

  create_table "adwords_groups", :primary_key => "adwords_group_id", :force => true do |t|
    t.string   "name",                       :null => false
    t.integer  "keywordMaxCpc",              :null => false
    t.integer  "campaign_id",                :null => false
    t.integer  "google_id",     :limit => 8, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "adwords_keywords", :primary_key => "adwords_keyword_id", :force => true do |t|
    t.string   "text",                          :null => false
    t.boolean  "paused",                        :null => false
    t.integer  "adwords_group_id",              :null => false
    t.integer  "google_id",        :limit => 8, :null => false
    t.datetime "created_at"
    t.datetime "removed_at"
    t.datetime "updated_at"
  end

  create_table "affiliate_log_line_items", :force => true do |t|
    t.integer "affiliate_log_id", :null => false
    t.integer "line_item_id",     :null => false
  end

  create_table "affiliate_logs", :force => true do |t|
    t.integer  "affiliate_id",                                                :null => false
    t.integer  "payment_id"
    t.decimal  "amount",       :precision => 7, :scale => 2, :default => 0.0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "note"
  end

  create_table "affiliate_transactions", :primary_key => "affiliate_transaction_id", :force => true do |t|
    t.string  "transaction_type",      :limit => 1,                               :default => "",  :null => false
    t.integer "affiliate_customer_id",                                            :default => 0,   :null => false
    t.integer "referred_customer_id"
    t.decimal "amount",                             :precision => 9, :scale => 2, :default => 0.0, :null => false
    t.date    "date",                                                                              :null => false
  end

  add_index "affiliate_transactions", ["affiliate_customer_id"], :name => "index_affiliate_transactions_on_affiliate_customer_id"

  create_table "affiliate_windows", :force => true do |t|
    t.integer  "user_id",      :null => false
    t.integer  "affiliate_id", :null => false
    t.datetime "start"
    t.datetime "end"
  end

  create_table "affiliates", :force => true do |t|
    t.integer  "user_id",                                                             :null => false
    t.integer  "window_length",                                      :default => 0,   :null => false
    t.decimal  "cut",                  :precision => 5, :scale => 4, :default => 0.0, :null => false
    t.decimal  "new_customer_payment", :precision => 4, :scale => 2, :default => 0.0, :null => false
    t.string   "encrypted_ssn"
    t.string   "code"
    t.datetime "created_at"
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

  create_table "authors", :primary_key => "author_id", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  create_table "campaigns", :force => true do |t|
    t.string   "name",               :limit => 32,                                :default => "", :null => false
    t.date     "start_date",                                                                      :null => false
    t.date     "end_date"
    t.decimal  "fixed_cost",                       :precision => 10, :scale => 2,                 :null => false
    t.decimal  "unit_cost",                        :precision => 10, :scale => 2,                 :null => false
    t.string   "coupon",             :limit => 32
    t.string   "ct_code",            :limit => 32
    t.string   "contact_email"
    t.string   "notes"
    t.integer  "cat_id"
    t.string   "initial_uri_regexp", :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaigns", ["cat_id"], :name => "index_campaigns_on_cat_id"

  create_table "campaigns_sent_to_customers", :primary_key => "campaigns_sent_to_customers_id", :force => true do |t|
    t.integer  "customerID",        :null => false
    t.integer  "email_campaign_id", :null => false
    t.datetime "created_at"
  end

  create_table "campaigns_sent_to_magazines", :primary_key => "campaigns_sent_to_magazines_id", :force => true do |t|
    t.integer  "magazine_id",       :null => false
    t.integer  "email_campaign_id", :null => false
    t.datetime "created_at"
  end

  create_table "cancellation_logs", :primary_key => "cancellation_log_id", :force => true do |t|
    t.boolean  "new_liveness",   :default => true, :null => false
    t.string   "reference_type",                   :null => false
    t.integer  "reference_id",                     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cart_items", :primary_key => "cart_item_id", :force => true do |t|
    t.integer  "cart_id",                                        :default => 0,     :null => false
    t.integer  "product_id",                                     :default => 0,     :null => false
    t.boolean  "saved_for_later",                                :default => false, :null => false
    t.datetime "created_at",                                                        :null => false
    t.decimal  "discount",        :precision => 10, :scale => 0
  end

  add_index "cart_items", ["cart_id"], :name => "cart_id"

  create_table "carts", :primary_key => "cart_id", :force => true do |t|
    t.integer "customer_id"
  end

  add_index "carts", ["customer_id"], :name => "index_carts_on_customer_id"

  create_table "categories", :primary_key => "category_id", :force => true do |t|
    t.string  "name",                :default => "", :null => false
    t.text    "description",                         :null => false
    t.integer "parent_id",           :default => 0,  :null => false
    t.string  "keywords"
    t.integer "display_category_id"
  end

  create_table "categories_dropins", :primary_key => "ID", :force => true do |t|
    t.integer "catID",              :default => 0, :null => false
    t.integer "dropinLiteratureID", :default => 0, :null => false
  end

  create_table "categories_products", :id => false, :force => true do |t|
    t.integer "product_id",  :null => false
    t.integer "category_id", :null => false
  end

  add_index "categories_products", ["category_id"], :name => "catID"
  add_index "categories_products", ["product_id"], :name => "titleID"

  create_table "cc_charge_statuses", :force => true do |t|
    t.integer  "credit_card_id",                               :null => false
    t.boolean  "status",                                       :null => false
    t.decimal  "amount",         :precision => 8, :scale => 2, :null => false
    t.string   "message",                                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cc_expirations", :force => true do |t|
    t.integer "payment_id"
    t.integer "month"
    t.integer "year"
  end

  create_table "chargeback_disputes", :force => true do |t|
    t.string   "order_id",     :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "hr_person_id", :null => false
  end

  create_table "cobrand_categories", :primary_key => "cobrand_category_id", :force => true do |t|
    t.integer "cobrand_id",  :default => 0, :null => false
    t.integer "category_id", :default => 0, :null => false
    t.integer "ordinal",     :default => 0, :null => false
  end

  add_index "cobrand_categories", ["category_id"], :name => "index_cobrand_categories_on_category_id"
  add_index "cobrand_categories", ["cobrand_id"], :name => "index_cobrand_categories_on_cobrand_id"

  create_table "cobrand_payments", :force => true do |t|
    t.integer "cobrand_id"
    t.date    "created_at"
    t.float   "payment"
  end

  create_table "cobrands", :primary_key => "cobrand_id", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  add_index "cobrands", ["name"], :name => "index_cobrands_on_name"

  create_table "comments", :force => true do |t|
    t.integer  "customer_id", :null => false
    t.integer  "parent_id",   :null => false
    t.string   "parent_type", :null => false
    t.text     "text",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["customer_id"], :name => "index_comments_on_customer_id"
  add_index "comments", ["parent_id"], :name => "index_comments_on_parent_id"

  create_table "contact_messages", :primary_key => "contact_message_id", :force => true do |t|
    t.string  "name",        :default => "", :null => false
    t.string  "email",       :default => "", :null => false
    t.text    "message",                     :null => false
    t.string  "ip_address",  :default => "", :null => false
    t.integer "customer_id"
    t.string  "user_agent",  :default => "", :null => false
  end

  create_table "contest_entries", :primary_key => "contest_entry_id", :force => true do |t|
    t.integer "contest_id"
    t.integer "customer_id", :default => 0,  :null => false
    t.string  "first_name",  :default => "", :null => false
    t.string  "last_name",   :default => "", :null => false
    t.string  "title",       :default => "", :null => false
    t.text    "description"
  end

  create_table "contest_entry_photos", :primary_key => "contest_entry_photo_id", :force => true do |t|
    t.integer "parent_id"
    t.string  "content_type"
    t.string  "filename"
    t.string  "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.string  "contest_entry_id", :default => "", :null => false
  end

  create_table "contest_ping_requests", :primary_key => "contest_ping_request_id", :force => true do |t|
    t.integer "contest_id", :default => 0,  :null => false
    t.string  "email",      :default => "", :null => false
  end

  create_table "contest_votes", :primary_key => "contest_vote_id", :force => true do |t|
    t.string  "voter_email",      :default => "", :null => false
    t.integer "contest_entry_id", :default => 0,  :null => false
  end

  create_table "contests", :primary_key => "contest_id", :force => true do |t|
    t.string   "title",        :default => "", :null => false
    t.text     "description",                  :null => false
    t.integer  "phase",        :default => 1
    t.datetime "archive_date"
  end

  create_table "copies", :primary_key => "copy_id", :force => true do |t|
    t.integer "product_id"
    t.date    "birthDATE"
    t.date    "deathDATE"
    t.integer "mediaformat",       :default => 2,     :null => false
    t.integer "status",            :default => 1,     :null => false
    t.integer "inStock",           :default => 1,     :null => false
    t.integer "tmpReserve",        :default => 0,     :null => false
    t.integer "death_type_id"
    t.boolean "visibleToShipperP", :default => true,  :null => false
    t.boolean "payPerRentP",       :default => false, :null => false
  end

  add_index "copies", ["birthDATE"], :name => "index_copies_on_birthDATE"
  add_index "copies", ["deathDATE"], :name => "index_copies_on_deathDATE"
  add_index "copies", ["product_id"], :name => "index_copies_on_product_id"

  create_table "copy_delays", :primary_key => "copy_delay_id", :force => true do |t|
    t.integer  "copy_id"
    t.integer  "delay"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "copy_delays", ["copy_id"], :name => "index_expected_delays_on_copy_id"

  create_table "countries", :primary_key => "country_id", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  create_table "coupons", :primary_key => "coupon_id", :force => true do |t|
    t.string   "code",                                             :default => "",    :null => false
    t.decimal  "amount",             :precision => 9, :scale => 2, :default => 0.0,   :null => false
    t.date     "start_date",                                                          :null => false
    t.date     "end_date",                                                            :null => false
    t.boolean  "new_customers_only",                               :default => false, :null => false
    t.boolean  "single_use_only",                                  :default => false, :null => false
    t.boolean  "active",                                           :default => true,  :null => false
    t.datetime "created_at",                                                          :null => false
  end

  add_index "coupons", ["code"], :name => "index_coupons_on_code"

  create_table "credit_cards", :primary_key => "credit_card_id", :force => true do |t|
    t.integer  "customer_id",      :default => 0,                     :null => false
    t.text     "encrypted_number",                                    :null => false
    t.integer  "month",            :default => 0,                     :null => false
    t.integer  "year",             :default => 0,                     :null => false
    t.string   "first_name",       :default => "",                    :null => false
    t.string   "last_name",        :default => "",                    :null => false
    t.string   "brand",            :default => "",                    :null => false
    t.string   "last_four"
    t.boolean  "disabled",         :default => false,                 :null => false
    t.integer  "extra_attempts",   :default => 0,                     :null => false
    t.datetime "created_at",       :default => '2001-01-01 01:01:01', :null => false
    t.datetime "updated_at",       :default => '2001-01-01 01:01:01', :null => false
  end

  create_table "customer_category_recommendations", :primary_key => "customer_category_recommendation_id", :force => true do |t|
    t.integer  "customer_id", :default => 0, :null => false
    t.integer  "category_id", :default => 0, :null => false
    t.integer  "ordinal",     :default => 0, :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "customer_category_recommendations", ["customer_id"], :name => "index_customer_category_recommendations_on_customer_id"

  create_table "customer_initiated_emails", :primary_key => "customer_initiated_email_id", :force => true do |t|
    t.integer  "customer_id"
    t.string   "recipient_email"
    t.integer  "product_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customer_product_recommendations", :primary_key => "customer_product_recommendation_id", :force => true do |t|
    t.integer  "customer_id", :default => 0, :null => false
    t.integer  "product_id",  :default => 0, :null => false
    t.integer  "ordinal",     :default => 0, :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  add_index "customer_product_recommendations", ["customer_id"], :name => "index_customer_product_recommendations_on_customer_id"

  create_table "customers", :primary_key => "customer_id", :force => true do |t|
    t.string   "email",                     :default => "",    :null => false
    t.string   "hashed_password",           :default => "",    :null => false
    t.string   "first_name",                :default => "",    :null => false
    t.string   "last_name",                 :default => "",    :null => false
    t.integer  "shipping_address_id",       :default => 0,     :null => false
    t.integer  "billing_address_id",        :default => 0,     :null => false
    t.boolean  "affiliate",                 :default => false, :null => false
    t.text     "encrypted_ssn"
    t.datetime "updated_at",                                   :null => false
    t.integer  "ship_rate",                 :default => 4,     :null => false
    t.integer  "posts_count",               :default => 0,     :null => false
    t.text     "bio"
    t.text     "bio_html"
    t.string   "display_name"
    t.boolean  "arrived_via_email_capture", :default => false, :null => false
    t.datetime "created_at",                                   :null => false
    t.date     "date_full_customer"
    t.string   "first_server_name"
    t.string   "first_ip_addr"
    t.integer  "first_university_id"
    t.boolean  "emailBouncedP",             :default => false, :null => false
    t.boolean  "throttleP",                 :default => false, :null => false
    t.string   "notes"
  end

  add_index "customers", ["email"], :name => "index_customers_on_email"

  create_table "death_logs", :primary_key => "deathLogID", :force => true do |t|
    t.integer "newDeathType"
    t.date    "editDate"
    t.string  "note"
    t.integer "copy_id"
  end

  create_table "death_types", :primary_key => "death_type_id", :force => true do |t|
    t.string "name"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "display_categories", :primary_key => "display_category_id", :force => true do |t|
    t.string  "name",  :default => "", :null => false
    t.integer "order", :default => 0,  :null => false
  end

  create_table "dvd_weights", :primary_key => "dvd_weight_id", :force => true do |t|
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

  create_table "email_preference_types", :primary_key => "email_preference_type_id", :force => true do |t|
    t.string "form_tag",    :default => "", :null => false
    t.string "name",        :default => "", :null => false
    t.string "description", :default => "", :null => false
  end

  create_table "email_preferences", :primary_key => "email_preference_id", :force => true do |t|
    t.integer  "customer_id",              :default => 0,     :null => false
    t.integer  "email_preference_type_id", :default => 0,     :null => false
    t.boolean  "send_email",               :default => false, :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "email_preferences", ["customer_id"], :name => "index_email_preferences_on_customer_id"

  create_table "favorite_project_links", :force => true do |t|
    t.integer  "customer_id", :null => false
    t.integer  "project_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favorite_project_links", ["customer_id"], :name => "index_favorite_project_links_on_customer_id"
  add_index "favorite_project_links", ["project_id"], :name => "index_favorite_project_links_on_project_id"

  create_table "featured_products", :primary_key => "featured_product_id", :force => true do |t|
    t.integer  "product_id", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "topics_count",     :default => 0
    t.integer "posts_count",      :default => 0
    t.integer "position"
    t.text    "description_html"
  end

  create_table "gift_certificates", :primary_key => "gift_certificate_id", :force => true do |t|
    t.string   "code",                                      :default => "",    :null => false
    t.decimal  "amount",      :precision => 9, :scale => 2
    t.boolean  "used",                                      :default => false, :null => false
    t.datetime "created_at",                                                   :null => false
    t.integer  "univ_months"
  end

  add_index "gift_certificates", ["code"], :name => "index_gift_certificates_on_code"

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

  create_table "inventory_ordereds", :primary_key => "inventory_ordered_id", :force => true do |t|
    t.integer "product_id",                :null => false
    t.integer "quant_dvd",  :default => 0, :null => false
  end

  add_index "inventory_ordereds", ["product_id"], :name => "index_inventory_ordereds_on_product_id"

  create_table "job_applications", :force => true do |t|
    t.string   "your_name"
    t.string   "your_email"
    t.text     "resume"
    t.string   "your_phone"
    t.string   "cover_letter"
    t.integer  "status",         :default => 1
    t.integer  "job_opening_id",                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "interview_slot"
  end

  create_table "job_openings", :force => true do |t|
    t.string   "name",                                 :null => false
    t.string   "compensation",                         :null => false
    t.text     "description",                          :null => false
    t.boolean  "live",               :default => true, :null => false
    t.integer  "position_open_days", :default => 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "job_references", :force => true do |t|
    t.string   "their_name"
    t.string   "their_email"
    t.string   "their_phone"
    t.string   "job_title"
    t.integer  "job_application_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "line_items", :primary_key => "line_item_id", :force => true do |t|
    t.integer  "order_id",                                             :default => 0,     :null => false
    t.integer  "product_id",                                           :default => 0,     :null => false
    t.decimal  "price",                  :precision => 9, :scale => 2, :default => 0.0,   :null => false
    t.integer  "shipment_id"
    t.boolean  "live",                                                 :default => true,  :null => false
    t.integer  "copy_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "dateBack"
    t.boolean  "actionable",                                           :default => true
    t.integer  "parent_line_item_id"
    t.boolean  "apologyCopyP"
    t.integer  "overdueGraceGranted",                                  :default => 0
    t.boolean  "wrongItemSent",                                        :default => false
    t.integer  "copy_id_intended"
    t.boolean  "return_email_sent"
    t.boolean  "refunded"
    t.boolean  "ignore_for_univ_limits",                               :default => false, :null => false
    t.integer  "queue_position"
    t.date     "lateMsg1Sent"
    t.date     "lateMsg2Sent"
    t.date     "lateMsg3Sent"
    t.datetime "lawsuit_snailmail"
    t.datetime "lawsuit_filed"
  end

  add_index "line_items", ["actionable"], :name => "index_line_items_on_actionable"
  add_index "line_items", ["copy_id"], :name => "index_line_items_on_copy_id"
  add_index "line_items", ["dateBack"], :name => "index_line_items_on_dateBack"
  add_index "line_items", ["lawsuit_snailmail"], :name => "index_line_items_on_lawsuit_snailmail"
  add_index "line_items", ["live"], :name => "index_line_items_on_uncancelledP"
  add_index "line_items", ["order_id"], :name => "index_line_items_on_order_id"
  add_index "line_items", ["parent_line_item_id"], :name => "index_line_items_on_parent_line_item_id"
  add_index "line_items", ["product_id"], :name => "index_line_items_on_product_id"
  add_index "line_items", ["shipment_id"], :name => "index_line_items_on_shipment_id"

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.string   "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "magazine_cats", :primary_key => "magazine_cat_id", :force => true do |t|
    t.string  "string_code",      :null => false
    t.string  "name",             :null => false
    t.integer "smartflix_cat_id"
  end

  create_table "magazines", :primary_key => "magazine_id", :force => true do |t|
    t.string  "title",    :null => false
    t.string  "street"
    t.string  "city"
    t.string  "state"
    t.string  "zip"
    t.string  "phone"
    t.string  "fax"
    t.string  "cat_code"
    t.integer "catID"
    t.integer "circ"
    t.string  "schedule"
    t.string  "readers"
    t.string  "editor"
    t.string  "url"
    t.string  "email"
  end

  create_table "migrations_info", :force => true do |t|
    t.datetime "created_at"
  end

  create_table "moderatorships", :force => true do |t|
    t.integer "forum_id"
    t.integer "user_id"
  end

  add_index "moderatorships", ["forum_id"], :name => "index_moderatorships_on_forum_id"

  create_table "monitorships", :force => true do |t|
    t.integer "topic_id"
    t.integer "user_id"
    t.boolean "active",   :default => true
  end

  create_table "newsletter_categories", :primary_key => "newsletter_category_id", :force => true do |t|
    t.text     "code"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletter_recipients", :primary_key => "newsletter_recipient_id", :force => true do |t|
    t.integer  "newsletter_id"
    t.integer  "customer_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletter_section_fields", :primary_key => "newsletter_section_field_id", :force => true do |t|
    t.integer  "newsletter_section_id", :null => false
    t.string   "field",                 :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletter_sections", :primary_key => "newsletter_section_id", :force => true do |t|
    t.integer  "newsletter_id", :null => false
    t.string   "section",       :null => false
    t.integer  "sequence"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "newsletters", :force => true do |t|
    t.string   "headline",                                  :null => false
    t.integer  "newsletter_category_id"
    t.integer  "total_recipients",       :default => 0
    t.boolean  "kill",                   :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notes", :primary_key => "note_id", :force => true do |t|
    t.integer  "notable_id",   :null => false
    t.string   "notable_type", :null => false
    t.string   "note",         :null => false
    t.integer  "employee_id",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_univ_dvd_rate_updates", :primary_key => "order_univ_dvd_rate_updates_id", :force => true do |t|
    t.integer  "univ_dvd_rate"
    t.string   "reference_type"
    t.integer  "reference_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id",       :null => false
    t.string   "note"
  end

  create_table "orders", :primary_key => "order_id", :force => true do |t|
    t.integer  "customer_id",       :default => 0,     :null => false
    t.string   "ip_address",        :default => "",    :null => false
    t.string   "server_name"
    t.string   "origin_code"
    t.integer  "university_id"
    t.boolean  "postcheckout_sale", :default => false, :null => false
    t.integer  "univ_dvd_rate"
    t.boolean  "unshippedMsgSentP"
    t.integer  "replacesShipment"
    t.integer  "prereqMsgSentP"
    t.date     "orderDate"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "live",              :default => true
    t.string   "ct_code"
  end

  add_index "orders", ["customer_id"], :name => "index_orders_on_customer_id"
  add_index "orders", ["origin_code"], :name => "index_orders_on_origin_code"

  create_table "origins", :force => true do |t|
    t.string   "referer"
    t.string   "first_uri"
    t.string   "first_coupon"
    t.string   "ct_code"
    t.integer  "session_id"
    t.integer  "customer_id"
    t.datetime "created_at"
    t.datetime "updated_at",   :null => false
    t.string   "user_agent"
  end

  add_index "origins", ["customer_id"], :name => "index_origins_on_customer_id"
  add_index "origins", ["first_coupon"], :name => "index_origins_on_first_coupon"
  add_index "origins", ["first_uri"], :name => "index_origins_on_first_uri"
  add_index "origins", ["referer"], :name => "index_origins_on_referer"
  add_index "origins", ["session_id"], :name => "index_origins_on_session_id"
  add_index "origins", ["updated_at"], :name => "index_origins_on_updated_at"

  create_table "other_ads", :force => true do |t|
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

  create_table "pageranks", :force => true do |t|
    t.date  "date",                        :null => false
    t.float "rank",       :default => 0.0, :null => false
    t.text  "searchterm"
  end

  create_table "payPerRentPayments", :primary_key => "payPerRent_payments_id", :force => true do |t|
    t.date    "datePaid",                                                :null => false
    t.integer "vendorID",                               :default => 0,   :null => false
    t.decimal "amount",   :precision => 4, :scale => 2, :default => 0.0, :null => false
  end

  create_table "payment_components", :primary_key => "payment_component_id", :force => true do |t|
    t.integer  "payment_id",                                   :default => 0,   :null => false
    t.decimal  "amount",         :precision => 9, :scale => 2, :default => 0.0, :null => false
    t.string   "payment_method",                               :default => "",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :primary_key => "payment_id", :force => true do |t|
    t.integer  "order_id"
    t.integer  "customer_id",                                         :default => 0,     :null => false
    t.string   "payment_method",                                      :default => "",    :null => false
    t.integer  "credit_card_id"
    t.decimal  "amount",                :precision => 9, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "amount_as_new_revenue", :precision => 9, :scale => 2, :default => 0.0,   :null => false
    t.string   "cart_hash"
    t.boolean  "complete",                                            :default => false, :null => false
    t.boolean  "successful",                                          :default => false, :null => false
    t.datetime "updated_at",                                                             :null => false
    t.integer  "status"
    t.integer  "retry_attempts",                                      :default => 0,     :null => false
    t.datetime "created_at"
    t.string   "message"
  end

  add_index "payments", ["customer_id"], :name => "index_payments_on_customer_id"
  add_index "payments", ["order_id"], :name => "index_payments_on_order_id"

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

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "topic_id"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "forum_id"
    t.text     "body_html"
  end

  add_index "posts", ["forum_id", "created_at"], :name => "index_posts_on_forum_id"
  add_index "posts", ["user_id", "created_at"], :name => "index_posts_on_user_id"

  create_table "potential_items", :primary_key => "potential_item_id", :force => true do |t|
    t.integer  "potential_shipment_id", :null => false
    t.integer  "copy_id"
    t.integer  "gift_cert_id"
    t.string   "type"
    t.integer  "line_item_id",          :null => false
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  add_index "potential_items", ["copy_id"], :name => "index_potential_items_on_copy_id"
  add_index "potential_items", ["gift_cert_id"], :name => "index_potential_items_on_gift_cert_id"

  create_table "potential_shipments", :primary_key => "potential_shipment_id", :force => true do |t|
    t.integer  "customer_id", :null => false
    t.text     "barcode",     :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "price_modifiers", :primary_key => "price_modifier_id", :force => true do |t|
    t.integer "order_id"
    t.string  "type",                                    :default => "",  :null => false
    t.decimal "amount",    :precision => 9, :scale => 2, :default => 0.0, :null => false
    t.integer "coupon_id"
  end

  add_index "price_modifiers", ["coupon_id"], :name => "index_price_modifiers_on_coupon_id"
  add_index "price_modifiers", ["order_id"], :name => "index_price_modifiers_on_order_id"

  create_table "product_bundle_memberships", :primary_key => "product_bundle_membership_id", :force => true do |t|
    t.integer "product_id"
    t.integer "product_bundle_id"
    t.integer "ordinal"
  end

  add_index "product_bundle_memberships", ["product_bundle_id"], :name => "index_product_bundle_memberships_on_product_bundle_id"
  add_index "product_bundle_memberships", ["product_id"], :name => "index_product_bundle_memberships_on_product_id"

  create_table "product_bundles", :primary_key => "product_bundle_id", :force => true do |t|
    t.string "name"
    t.float  "discount_multiplier"
    t.text   "description"
  end

  create_table "product_delays", :primary_key => "product_delay_id", :force => true do |t|
    t.integer  "product_id", :null => false
    t.integer  "ordinal",    :null => false
    t.integer  "days_delay", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_recommendations", :primary_key => "product_recommendation_id", :force => true do |t|
    t.integer  "product_id",             :default => 0, :null => false
    t.integer  "recommended_product_id", :default => 0, :null => false
    t.integer  "ordinal",                :default => 0, :null => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "product_recommendations", ["product_id"], :name => "index_product_recommendations_on_product_id"

  create_table "product_set_memberships", :primary_key => "product_set_membership_id", :force => true do |t|
    t.integer "product_id",     :default => 0, :null => false
    t.integer "product_set_id", :default => 0, :null => false
    t.integer "ordinal",        :default => 0, :null => false
  end

  add_index "product_set_memberships", ["product_id"], :name => "index_product_set_memberships_on_product_id"
  add_index "product_set_memberships", ["product_set_id"], :name => "index_product_set_memberships_on_product_set_id"

  create_table "product_sets", :primary_key => "product_set_id", :force => true do |t|
    t.string  "name",                                              :default => "",    :null => false
    t.boolean "describe_each_title",                               :default => false, :null => false
    t.decimal "discount_multiplier", :precision => 4, :scale => 2, :default => 0.0,   :null => false
    t.boolean "order_matters",                                     :default => false, :null => false
  end

  create_table "products", :primary_key => "product_id", :force => true do |t|
    t.string   "type",                                         :default => "",    :null => false
    t.string   "name",                                         :default => "",    :null => false
    t.text     "description",                                                     :null => false
    t.decimal  "price",          :precision => 9, :scale => 2, :default => 0.0,   :null => false
    t.date     "date_added",                                                      :null => false
    t.integer  "author_id",                                    :default => 0,     :null => false
    t.integer  "minutes",                                      :default => 0,     :null => false
    t.boolean  "display",                                      :default => true,  :null => false
    t.string   "handout"
    t.integer  "num_copies",                                   :default => 0
    t.decimal  "purchase_price", :precision => 6, :scale => 2, :default => 0.0
    t.integer  "university_id"
    t.integer  "vendor_id",                                                       :null => false
    t.boolean  "virtual",                                      :default => false, :null => false
    t.string   "part_number"
    t.boolean  "in_print",                                     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["university_id"], :name => "index_products_on_university_id"
  add_index "products", ["vendor_id"], :name => "index_products_on_vendor_id"

  create_table "project_images", :force => true do |t|
    t.integer  "project_update_id"
    t.integer  "parent_id"
    t.string   "content_type"
    t.string   "filename"
    t.string   "thumbnail"
    t.integer  "width"
    t.integer  "height"
    t.integer  "size"
    t.text     "caption"
    t.text     "caption_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_images", ["parent_id"], :name => "index_project_images_on_parent_id"
  add_index "project_images", ["project_update_id"], :name => "index_project_images_on_project_update_id"

  create_table "project_updates", :force => true do |t|
    t.integer  "project_id", :null => false
    t.text     "text"
    t.text     "text_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "project_updates", ["project_id"], :name => "index_project_updates_on_project_id"

  create_table "projects", :force => true do |t|
    t.integer  "customer_id",    :null => false
    t.string   "title",          :null => false
    t.integer  "status",         :null => false
    t.integer  "inspired_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects", ["customer_id"], :name => "index_projects_on_customer_id"
  add_index "projects", ["inspired_by_id"], :name => "index_projects_on_inspired_by_id"

  create_table "promotion_pages", :primary_key => "promotion_page_id", :force => true do |t|
    t.integer "promotion_id", :default => 0, :null => false
    t.integer "order",        :default => 0, :null => false
    t.text    "content"
  end

  create_table "promotions", :primary_key => "promotion_id", :force => true do |t|
    t.boolean "on"
    t.string  "tagline"
    t.text    "css"
    t.string  "default_status"
    t.string  "display_page",                :default => "^(\\/|\\/index)$"
    t.boolean "sticky",                      :default => true
    t.string  "close_button"
    t.string  "minimize_button"
    t.string  "maximize_button"
    t.string  "next_button"
    t.string  "previous_button"
    t.string  "audience"
    t.boolean "hide_next_on_last_page"
    t.boolean "hide_previous_on_first_page"
    t.string  "ab_test_name"
    t.string  "ab_test_alternative"
  end

  create_table "purchasers", :force => true do |t|
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

  create_table "ratings", :primary_key => "rating_id", :force => true do |t|
    t.integer  "product_id",  :default => 0, :null => false
    t.integer  "customer_id", :default => 0, :null => false
    t.integer  "rating",      :default => 0, :null => false
    t.datetime "created_at",                 :null => false
    t.text     "review"
    t.boolean  "approved"
  end

  add_index "ratings", ["customer_id"], :name => "index_ratings_on_customer_id"
  add_index "ratings", ["product_id"], :name => "index_ratings_on_product_id"

  create_table "scheduled_emails", :primary_key => "scheduled_email_id", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "product_id"
    t.string   "email_type",   :default => "recommendation"
    t.datetime "created_at"
    t.string   "product_type"
    t.datetime "updated_at"
  end

  add_index "scheduled_emails", ["customer_id"], :name => "index_scheduled_emails_on_customer_id"
  add_index "scheduled_emails", ["product_id"], :name => "index_scheduled_emails_on_product_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

  create_table "shipments", :primary_key => "shipment_id", :force => true do |t|
    t.date     "dateOut"
    t.date     "dateLost"
    t.integer  "replacedWithOrder"
    t.datetime "time_out",                             :null => false
    t.boolean  "email_sent",        :default => false, :null => false
    t.boolean  "boxP",              :default => true,  :null => false
    t.boolean  "physical",          :default => true,  :null => false
    t.datetime "updated_at",                           :null => false
  end

  add_index "shipments", ["dateOut"], :name => "index_shipments_on_dateOut"

  create_table "states", :primary_key => "state_id", :force => true do |t|
    t.string "name", :default => "", :null => false
    t.string "code", :default => "", :null => false
  end

  create_table "suggestions", :primary_key => "suggestion_id", :force => true do |t|
    t.string  "name",         :default => "", :null => false
    t.string  "email",        :default => "", :null => false
    t.string  "title",        :default => "", :null => false
    t.string  "where_to_buy", :default => "", :null => false
    t.string  "ip_address",   :default => "", :null => false
    t.integer "customer_id"
  end

  create_table "survey_answers", :primary_key => "survey_answer_id", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "survey_question_id"
    t.integer  "order_id"
    t.string   "answer"
    t.datetime "created_at"
  end

  create_table "survey_questions", :primary_key => "survey_question_id", :force => true do |t|
    t.integer "survey_id",        :default => 0, :null => false
    t.string  "question"
    t.text    "answer_html"
    t.string  "answer_validator"
  end

  create_table "surveys", :primary_key => "survey_id", :force => true do |t|
    t.string "name"
  end

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
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "topics", :force => true do |t|
    t.integer  "forum_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hits",         :default => 0
    t.integer  "sticky",       :default => 0
    t.integer  "posts_count",  :default => 0
    t.datetime "replied_at"
    t.boolean  "locked",       :default => false
    t.integer  "replied_by"
    t.integer  "last_post_id"
  end

  add_index "topics", ["forum_id", "replied_at"], :name => "index_topics_on_forum_id_and_replied_at"
  add_index "topics", ["forum_id", "sticky", "replied_at"], :name => "index_topics_on_sticky_and_replied_at"
  add_index "topics", ["forum_id"], :name => "index_topics_on_forum_id"

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

  create_table "universities", :primary_key => "university_id", :force => true do |t|
    t.string   "name",                                                :default => "",    :null => false
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
    t.decimal  "subscription_charge",   :precision => 9, :scale => 2, :default => 24.94, :null => false
    t.integer  "category_id",                                         :default => 0,     :null => false
    t.integer  "charge_level",                                        :default => 1,     :null => false
    t.string   "featured_product_type"
    t.integer  "featured_product_id"
    t.string   "verb_str"
  end

  create_table "university_curriculum_elements", :primary_key => "university_curriculum_element_id", :force => true do |t|
    t.integer  "video_id",      :default => 0, :null => false
    t.integer  "university_id", :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "university_curriculum_elements", ["university_id"], :name => "index_university_curriculum_elements_on_university_id"
  add_index "university_curriculum_elements", ["video_id"], :name => "index_university_curriculum_elements_on_video_id"

  create_table "university_host_names", :primary_key => "university_host_name_id", :force => true do |t|
    t.string   "hostname",      :default => "", :null => false
    t.integer  "university_id", :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "upsell_offers", :primary_key => "upsell_offer_id", :force => true do |t|
    t.integer  "customer_id",     :default => 0,  :null => false
    t.string   "reco_type",       :default => "", :null => false
    t.integer  "reco_id",         :default => 0,  :null => false
    t.integer  "base_order_id",   :default => 0,  :null => false
    t.integer  "upsell_order_id"
    t.integer  "ordinal",         :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "url_tracks", :primary_key => "url_track_id", :force => true do |t|
    t.string   "session_id",  :default => "", :null => false
    t.integer  "customer_id"
    t.string   "path",        :default => "", :null => false
    t.string   "controller",  :default => "", :null => false
    t.string   "action",      :default => "", :null => false
    t.string   "action_id"
    t.datetime "created_at",                  :null => false
  end

  create_table "usps_postage_charts", :force => true do |t|
    t.text    "usps_physical"
    t.string  "usps_class",      :null => false
    t.integer "weight_oz",       :null => false
    t.integer "price_cents",     :null => false
    t.integer "zone"
    t.date    "rate_start_date", :null => false
    t.date    "rate_end_date",   :null => false
  end

  create_table "usps_postage_forms", :force => true do |t|
    t.string   "form_name",  :null => false
    t.datetime "created_at", :null => false
    t.integer  "person_id",  :null => false
  end

  create_table "vendor_moods", :primary_key => "vendor_mood_id", :force => true do |t|
    t.string "moodText"
  end

  create_table "vendor_order_logs", :primary_key => "vendor_order_log_id", :force => true do |t|
    t.integer "product_id",                  :null => false
    t.date    "orderDate",                   :null => false
    t.integer "quant",        :default => 0, :null => false
    t.integer "purchaser_id"
  end

  create_table "vendors", :primary_key => "vendor_id", :force => true do |t|
    t.string  "name",                              :null => false
    t.integer "vendor_mood_id",                    :null => false
    t.boolean "outOfBusinessP", :default => false, :null => false
    t.string  "notes"
    t.string  "emailAddr"
    t.boolean "advertiseP",     :default => true,  :null => false
  end

  create_table "video_assets", :primary_key => "video_asset_id", :force => true do |t|
    t.date     "acquired",   :null => false
    t.integer  "dollars",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wiki_page_associations", :force => true do |t|
    t.integer  "wiki_page_id",     :default => 0,  :null => false
    t.integer  "association_id",   :default => 0,  :null => false
    t.string   "association_type", :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wiki_page_versions", :force => true do |t|
    t.integer  "wiki_page_id"
    t.integer  "version"
    t.integer  "customer_id",  :default => 0
    t.string   "name",         :default => ""
    t.text     "content"
    t.text     "content_html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "wiki_pages", :force => true do |t|
    t.integer  "customer_id",  :default => 0,  :null => false
    t.string   "name",         :default => "", :null => false
    t.text     "content",                      :null => false
    t.text     "content_html",                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version"
  end

end

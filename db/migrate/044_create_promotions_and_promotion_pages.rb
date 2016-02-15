class CreatePromotionsAndPromotionPages < ActiveRecord::Migration
  def self.up
    create_table(:promotions, :primary_key => 'promotion_id') do |t|
      t.column :on, :boolean
      t.column :tagline, :string
      t.column :css, :text
      t.column :default_status, :string
      t.column :display_page, :string, :default => '^(\/|\/index)$'
      t.column :sticky, :boolean, :default => true
      t.column :close_button, :string
      t.column :minimize_button, :string
      t.column :maximize_button, :string
      t.column :next_button, :string
      t.column :previous_button, :string
      t.column :audience, :string
      t.column :hide_next_on_last_page, :boolean
      t.column :hide_previous_on_first_page, :boolean
    end
    
    create_table(:promotion_pages, :primary_key => 'promotion_page_id') do |t|
      t.column :promotion_id, :integer, :null => false
      t.column :order, :integer, :null => false
      t.column :content, :text
    end
  end

  def self.down
    drop_table :promotion_pages
    drop_table :promotions
  end
end

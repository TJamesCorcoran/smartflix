class SetupNewsletterEditor < ActiveRecord::Migration
  def self.up
    create_table 'newsletters', :primary_key => 'newsletter_id' do |t|
      t.string 'headline', :null => false
      t.integer 'newsletter_category_id'
      t.integer 'total_recipients', :default => 0
      t.boolean 'kill', :default => false

      t.timestamps
    end
    create_table 'newsletter_sections', :primary_key => 'newsletter_section_id' do |t|
      t.integer 'newsletter_id', :null => false
      t.string 'section', :null => false
      t.integer 'sequence'
      t.timestamps
    end
    create_table 'newsletter_section_fields', :primary_key => 'newsletter_section_field_id' do |t|
      t.integer 'newsletter_section_id', :null => false
      t.string 'field', :null => false
      t.text 'data'

      t.timestamps
    end
    create_table 'newsletter_categories', :primary_key => 'newsletter_category_id' do |t|
      t.text 'code'
      t.string 'name'

      t.timestamps
    end
    create_table 'newsletter_recipients', :primary_key => 'newsletter_recipient_id' do |t|
      t.integer 'newsletter_id', 'customer_id'
      t.string 'status'

      t.timestamps
    end
  end

  def self.down
    drop_table 'newsletter_recipients'
    drop_table 'newsletter_categories'
    drop_table 'newsletter_section_fields'
    drop_table 'newsletter_sections'
    drop_table 'newsletters'
  end
end

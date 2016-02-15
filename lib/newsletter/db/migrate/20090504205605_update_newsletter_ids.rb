class UpdateNewsletterIds < ActiveRecord::Migration

  # Rails builting rename column drops auto_increment for primary keys
  def self.rename_primary_key_column(table, old, new)
    execute "ALTER TABLE #{table} CHANGE COLUMN #{old} #{new} INT NOT NULL AUTO_INCREMENT;"
  end

  def self.up
    # Go to standard rails convention
    rename_primary_key_column :newsletters, :newsletter_id, :id
    rename_primary_key_column :newsletter_sections, :newsletter_section_id, :id
    rename_primary_key_column :newsletter_section_fields, :newsletter_section_field_id, :id
    rename_primary_key_column :newsletter_categories, :newsletter_category_id, :id
    rename_primary_key_column :newsletter_recipients, :newsletter_recipient_id, :id
    # Add some indexes while we're here
    add_index :newsletters, :newsletter_category_id
    add_index :newsletter_sections, :newsletter_id
    add_index :newsletter_section_fields, :newsletter_section_id
    add_index :newsletter_recipients, :newsletter_id
    add_index :newsletter_recipients, :customer_id
  end

  def self.down
    rename_primary_key_column :newsletters, :id, :newsletter_id
    rename_primary_key_column :newsletter_sections, :id, :newsletter_section_id
    rename_primary_key_column :newsletter_section_fields, :id, :newsletter_section_field_id
    rename_primary_key_column :newsletter_categories, :id, :newsletter_category_id
    rename_primary_key_column :newsletter_recipients, :id, :newsletter_recipient_id
  end
end

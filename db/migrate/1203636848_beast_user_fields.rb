class BeastUserFields < ActiveRecord::Migration
  def self.up
    add_column :customers, :posts_count, :integer
    add_column :customers, :bio, :text
    add_column :customers, :bio_html, :text
    add_column :customers, :display_name, :string

    execute "UPDATE customers SET display_name = first_name"
  end

  def self.down
    remove_column :customers, :posts_count
    remove_column :customers, :bio
    remove_column :customers, :bio_html
    remove_column :customers, :display_name, :string
  end
end

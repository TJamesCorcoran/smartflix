class ProjectCommentNoHtml < ActiveRecord::Migration
  def self.up
    remove_column :comments, :text_html
  end

  def self.down
    add_column :comments, :text_html, :text, :null => false
  end
end

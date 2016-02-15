class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table(:categories, :primary_key => 'category_id') do |t|
      t.column :name,        :string,  :null => false
      t.column :description, :text,    :null => false
      t.column :parent_id,   :integer, :null => false
      t.column :keywords,    :string,  :null => true, :default => nil
    end
  end

  def self.down
    drop_table :categories
  end
end

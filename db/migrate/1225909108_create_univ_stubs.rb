class CreateUnivStubs < ActiveRecord::Migration
  def self.up
    add_column :products, :university_id, :integer, :default =>nil, :null => true
    add_index  :products, :university_id

    create_table :adwords_categories, :primary_key => 'adwords_category_id' do |t|
      t.string :alternate_text
      t.string :additional_keywords
    end
  end

  def self.down
    remove_column :products, :university_id

    drop_table :adwords_categories
  end
end

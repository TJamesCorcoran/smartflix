class CreateDisplayCategories < ActiveRecord::Migration
  def self.up
    create_table(:display_categories, :primary_key => 'display_category_id') do |t|
      t.column :name, :string, :null => false
      t.column :order, :integer, :null => false
    end

    if APPLICATION_NAME == "tvr-master"
      add_column :category, :display_category_id, :integer
    else
      add_column :categories, :display_category_id, :integer
    end

    display_cats = [
      "Arts & Crafts",
      "Metalworking",
      "Vehicles",
      "Firearms",
      "Woodworking",
      "Film",
      "Digital Art - 2D",
      "Construction",
      "Sports & Outdoor",
      "Software Training",
      "Knifemaking",
      "Hobbies",
      "Digital Art - 3D",
      "Aircraft Piloting",
      "Academic",
      "Everything Else" ]

    display_cats.each_with_index { |c,i| DisplayCategory.create(:name => c, :order => i) }

    assigns = { 3 => 16, 5 => 16, 6 => 16, 9 => 11, 39 => 16, 70 => 14, 107 => 16, 108 => 1, 109 => 6, 
                110 => 16, 111 => 8, 112 => 16, 113 => 4, 114 => 12, 115 => 2, 116 => 16, 117 => 3, 
                118 => 5, 119 => 9, 146 => 16, 182 => 16, 212 => 10, 213 => 16, 218 => 16, 225 => 15,
                240 => 13, 241 => 7, 242 => 16, 243 => 16, 267 => 16 }

    assigns.each { |k,v| Category.find(k).update_attributes(:display_category_id => v) }
  end

  def self.down
    drop_table :display_categories
    if APPLICATION_NAME == "tvr-master"
      remove_column :category, :display_category_id
    else
      remove_column :categories, :display_category_id
    end
  end
end

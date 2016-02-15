class CreateCobrandCategories < ActiveRecord::Migration
  def self.up
    create_table(:cobrand_categories, :primary_key => 'cobrand_category_id') do |t|
      t.column :cobrand_id, :integer, :null => false
      t.column :category_id, :integer, :null => false
      t.column :ordinal, :integer, :null => false
    end
    add_index :cobrand_categories, :cobrand_id
    add_index :cobrand_categories, :category_id

    make_cobrand = Cobrand.find_by_name('makezine')
    category_ids = [110, 3, 5, 111, 112, 6, 114, 218, 9, 107, 39, 115, 117, 118]
    category_ids.each_with_index do |id, ordinal|
      CobrandCategory.create(:cobrand => make_cobrand, :category => Category.find(id), :ordinal => ordinal + 1)
    end

    craft_cobrand = Cobrand.find_by_name('craftzine')
    category_ids = [126, 148, 128, 161, 149, 22, 80, 190, 186, 7, 42, 132, 155, 49, 91, 265, 167, 160, 151, 87, 159, 62,
                    162, 63, 98, 41, 40, 172, 197, 127, 47, 174, 89, 101, 158, 150]
    category_ids.each_with_index do |id, ordinal|
      CobrandCategory.create(:cobrand => craft_cobrand, :category => Category.find(id), :ordinal => ordinal + 1)
    end

  end

  def self.down
    drop_table :cobrand_categories
  end
end

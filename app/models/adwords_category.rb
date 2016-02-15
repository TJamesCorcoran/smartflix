class AdwordsCategory < ActiveRecord::Base

  self.table_name = 'adwords_categories'
  self.primary_key = 'adwords_category_id'
  belongs_to :category, :foreign_key => 'catID'
end

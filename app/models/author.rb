class Author < ActiveRecord::Base
  self.primary_key = "author_id"
  attr_protected # <-- blank means total access


  has_many :products
  belongs_to :vendorMood

  def <=>(a)      0  end

  # Return the list of all products that should be listed -- for
  # example, we only list the first item in a set; takes an optional
  # argument that specifies how things should be sorted (it's a
  # ProductSortOption object)
  def listable_products(sort_option = nil)
    Product.select_listable_and_sort(self.products, sort_option)
  end



  def categories() products.map { |product| product.categories}.flatten end

  def major_cat() categories.sort_by_frequency.last end
  
  def major_cat_text() major_cat.good_human_name  end
  
  validates_uniqueness_of :name,
         :message => "is a duplicate"

  validates_format_of :name,
         :with => /[^ ]+/,
         :message => "is missing or invalid"

  def url(ctcode = nil) "http://#{SMARTFLIX_SmartFlix::Application::WEB_SERVER}/store/author/#{to_param}/#{ApplicationHelper.link_seo_for(self.name)}#{'?ct=' + ctcode if !ctcode.nil? }"   end

end

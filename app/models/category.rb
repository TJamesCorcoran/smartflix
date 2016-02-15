class Category < ActiveRecord::Base
  self.primary_key = "category_id"
  attr_accessor :indented, :selected
  attr_protected # <-- blank means total access

  belongs_to              :display_category
  belongs_to              :parent, :foreign_key => 'parent_id', :class_name => 'Category'
  belongs_to              :parentCat, :foreign_key => 'parent_id', :class_name => 'Category'
  has_and_belongs_to_many :products, :join_table => 'categories_products'
#  has_many                :adwords_ads, :as => :thing_advertised
  has_many                :campaigns,  :foreign_key => 'cat_id'
  has_many                :childCats, :foreign_key => 'parent_id', :class_name => 'Category'
  has_many                :children, :foreign_key => 'parent_id', :class_name => 'Category', :order => 'name'
  has_many                :universities
  has_many                :universities

#  has_many                :ebayAuctions
#  has_many                :magazines
#  has_many                :oreillyCategory

  def all_universities()
    [self, children].flatten.map(&:universities).flatten.uniq
  end

  has_many :product_bundles,
  :finder_sql => proc { "SELECT product_bundles.*
                             FROM product_bundles, product_bundle_memberships, products, categories_products
                            WHERE product_bundles.product_bundle_id = product_bundle_memberships.product_bundle_id
                              AND product_bundle_memberships.product_id = products.product_id
                              AND products.product_id = categories_products.product_id
                              AND categories_products.category_id = #{self.category_id}
                         GROUP BY product_bundles.product_bundle_id" }
#  has_many :wiki_page_associations, :as => :association
#  has_many :wiki_pages, :through => :wiki_page_associations
  has_one  :adwords_category, :foreign_key => 'adwords_category_id'


  # Return all customers who have either rented or browsed this category.
  # 
  # If we don't provide counter_sql, rails tries to construct it itself...and gets it wrong.
  #
  has_many :customers, :finder_sql => proc { '(SELECT customers.* 
                                        FROM customers, orders, line_items, categories_products, categories 
                                        WHERE customers.customer_id = orders.customer_id  
                                        AND orders.order_id = line_items.order_id 
                                        AND line_items.product_id = categories_products.product_id 
                                        AND categories_products.category_id = categories.category_id 
                                        AND (categories.category_id = #{id} || categories.parent_id = #{id} )  )
                                      UNION (
                                        SELECT customers.* 
                                        FROM  customers, url_tracks, categories_products, categories 
                                        WHERE customers.customer_id = url_tracks.customer_id 
                                        AND url_tracks.controller = "store" 
                                        AND url_tracks.action = "video" 
                                        AND url_tracks.action_id = categories_products.product_id 
                                        AND categories_products.category_id = categories.category_id 
                                        AND (categories.category_id = #{id} || categories.parent_id = #{id} ) )' },
  :counter_sql => proc { 'select count(1) from ((SELECT customers.* 
                                        FROM customers, orders, line_items, categories_products, categories 
                                        WHERE customers.customer_id = orders.customer_id  
                                        AND orders.order_id = line_items.order_id 
                                        AND line_items.product_id = categories_products.product_id 
                                        AND categories_products.category_id = categories.category_id 
                                        AND (categories.category_id = #{id} || categories.parent_id = #{id} )  )
                                      UNION (
                                        SELECT customers.* 
                                        FROM  customers, url_tracks, categories_products, categories 
                                        WHERE customers.customer_id = url_tracks.customer_id 
                                        AND url_tracks.controller = "store" 
                                        AND url_tracks.action = "video" 
                                        AND url_tracks.action_id = categories_products.product_id 
                                        AND categories_products.category_id = categories.category_id 
                                        AND (categories.category_id = #{id} || categories.parent_id = #{id} ) )) zzz' }

  has_many :customers_who_browsed, 
           :class_name => "Customer",
  :finder_sql => proc {'SELECT customers.* 
                          FROM customers
                          WHERE customer_id in (
                              SELECT customer_id 
                              FROM (
                                  SELECT customer_id, count(1) as cnt 
                                  FROM url_tracks, categories_products, categories cat
                                  WHERE controller = "store"
                                  AND action = "video"  
                                  AND ! ISNULL(customer_id)  
                                  AND action_id = product_id 
                                  AND categories_products.category_id = cat.category_id 
                                  AND (cat.category_id = #{self.category_id} OR cat.parent_id = #{self.category_id})
                                  GROUP BY customer_id) customers_and_browse_count
                              WHERE cnt > 2)' }



  #------------------------------
  # category tree 
  #------------------------------

  def <=>(cat2)    id <=> cat2.id  end
  def top_level()    parent_id == 0  end
  def toplevel?()   self.parent_id == 0  end
  def high_level_cat()    top_level ? self : parentCat  end
  def wiki_pages_plus()    (wiki_pages + children.map { |c| c.wiki_pages }.flatten).uniq  end



  # Return the list of all products that should be listed -- for
  # example, we only list the first item in a set; takes an optional
  # argument that specifies how things should be sorted (it's a
  # ProductSortOption object)
  def listable_products(sort_option = nil)
    Product.select_listable_and_sort(self.products, sort_option)
  end


  # Return the full category path to this category, ie parent::child, as an array
  def full_path()
    path = [self]
    path.unshift(self.parent) if !self.toplevel?
    return path
  end

  # Return the full category path to this category, ie parent::child, as a string
  def full_path_text(seperator = '::')
    return self.full_path.collect { |c| c.name }.join(seperator)
  end

  def descriptionOrAlt()
    ( adwords_category.nil? || 
      adwords_category.alternate_text.nil? ||
      adwords_category.alternate_text.empty?) ?
            name :
            adwords_category.alternate_text
  end

  # Return an array of categories to be displayed in a navigation
  # context; the indented and selected properties are set appropriately
  # on each category; a selected category is an optional argument.

  def self.display_list(selected_cat = nil)

    categories = Category.find(:all, :order => 'name')

    # Always list all top level, list subcats if needed
    top_cats = []
    sub_cats = []

    categories.each do |c|

      # Test for toplevel display
      top_cats << c if (c.toplevel?)

      # Just keep going if nothing is selected
      next if selected_cat.nil?

      # See if this cat is selected
      c.selected = true if (c.id == selected_cat.id)

      # Test for indented sublevel display, show if selected toplevel has subcats or a subcat is selected
      if ((selected_cat.toplevel? && c.parent_id == selected_cat.id) ||
          (!selected_cat.toplevel? && c.parent_id == selected_cat.parent_id))
        c.indented = true
        sub_cats << c
      end

    end

    # Insert the sub cats into the right part of the list of categories that we return for display
    if (sub_cats.size > 0)
      insert_cat_id = selected_cat.toplevel? ? selected_cat.id : selected_cat.parent_id
      index = top_cats.index(top_cats.detect { |c| c.id == insert_cat_id }) + 1
      top_cats[index, 0] = sub_cats
    end

    return top_cats

  end

  # Return a similar list of categories, but specific to a cobrand

  def self.display_list_for_cobrand(cobrand, selected_cat = nil)
    cobrand = Cobrand.find_by_name(cobrand)
    categories = cobrand.categories
    if selected_cat
      selected_parent = categories.include?(selected_cat) ? selected_cat : selected_cat.parent
      if selected_parent
        sub_cats = selected_parent.children
        selected_index = categories.index(selected_parent)
        categories[selected_index + 1, 0] = sub_cats.each { |cat| cat.indented = true } if selected_index
      end
    end
    categories.each { |cat| cat.selected = true if cat == selected_cat }
  end

  # Return the featured categories; either the most popular categories
  # if no user specified or, if a customer is passed in via the
  # :customer option, some categories that that customer might like.

  def self.featured(options = {})

    options.assert_valid_keys(:customer)

    if (options[:customer])
      categories = options[:customer].recommended_categories.sort_by { rand }
    end

    if (categories.nil? || categories.size == 0)
      # XXXFIX P3: Get which ones are featured by default from DB
      featured = [108, 115]
      categories = Category.find(:all, :conditions => "category_id IN (#{featured.join(',')})")
    end

    return categories

  end



  #----------
  # customer search
  #----------

  # # This gives us Category.find_by_contents
  # acts_as_ferret(:fields =>
  #                { :name => { :boost => 1.5 },
  #                  :keywords => { :boost => 1.0 }
  #                })

  def self.searchable_type() 'Category' end

  # define_index do
  #   indexes :name, :sortable => true
  # end



  #------------------------------
  # products
  #------------------------------

  def all_products()    (products + childCats.map {|child| child.products }).flatten  end
  
  def top_rated(n = 5)
    products.sort_by {|product| product.avg_rating || 0 }.reverse[0,n]
  end

  def products_by_birth_date(after=nil)
    products = self.products.reject{|product| product.birth_date.nil?}
    return products if after.nil?
    products.reject{|product| (after && product.birth_date.to_datetime < after) || product.birth_date.nil?}.sort{|a,b| b.birth_date.to_datetime <=> a.birth_date.to_datetime}
  end

  def products_for_display
    products.select { |pp| bo = pp.days_backorder; bo && bo < ProductDelay::CUTOFF_TO_DISPLAY }
  end

  #------------------------------
  # hierarchy
  #------------------------------
  def leaf?
    childCats.empty?
  end

  def self.all_leafs
    cat_ids = connection.select_values("select category_id from ( select count(1) as cnt, cat.* from categories cat left join categories chil on cat.category_id = chil.parent_id group by cat.category_id ) mix where cnt = 1;").map(&:to_i).map(&:to_i)
    Category.find(:all, :conditions => { :category_id => cat_ids })
  end


  #------------------------------
  # names, verbs, keywords, etc.
  #------------------------------

  # full breadcrumb name, 
  #    e.g. "Arts & Crafts : Painting : Oil "
  def full_name ()
    fullpathArray = Array.new
    node = self
    begin
      fullpathArray.unshift(node.name)
      node = node.parentCat
    end until (node.nil?)

    return fullpathArray.join(":")
  end

  # a more human name, good for using in ad copy, sentences, etc.
  #    e.g. "Oil Painting"
  def good_human_name
    name
  end

  def keywords_list
    keywords.split(":").reject {|x| x == "" }
  end
  
  #------------------------------
  # customers
  #------------------------------

  def url
    "http://smartflix.com/store/category/#{catID}"
  end

  def customers_firstorder_in_cat(begindate = nil, enddate = nil)
    begindate ||= Date.parse("1900-01-01")
    enddate   ||= Date.parse("2100-01-01")
    Customer.connection.select_all("SELECT DISTINCT customer.*
                                       FROM customer
                                       WHERE first_order_date >= '#{begindate}'
                                       AND   first_order_date <= '#{enddate}'
                                       AND (firstorder_cat_leaf = #{id} || firstorder_cat_root = #{id} )")

  end

  #------------------------------
  # misc
  #------------------------------

  def create_university
    return universities if universities.any?
    University.create_new(:category => self, 
                          :name => "#{name} University",
                          :title_id_list => UNIV_RESEARCH_all_fourstar_products_and_sequels() )
  end

  #------------------------------
  # data mining
  #------------------------------


  # XYZ P3: we really want to look not just at new custs the month the ad runs, but in the 1-3 months after
  def DATAMINE_correllate_ads_and_newcustomers_cat
    
    data = Date.parse("2005-01-01").upto_bymonth_array(Date.today >> 1).map do |month|
      [ month.to_s,
        self.customers_firstorder_in_cat(month.beginning_of_month, month.end_of_month).size,
        self.campaigns.select { |camp| camp.live_at(month)}.size
      ]
    end
    StatArray.correl(data)
  end

  def DATAMINE_correllate_ads_and_newcustomers_all
    
    data = Date.parse("2005-01-01").upto_bymonth_array(Date.today >> 1).map do |month|
      [ month.to_s,
        month.customers_this_month.size,
        self.campaigns.select { |camp| camp.live_at(month)}.size
      ]
    end
    StatArray.correl(data)
  end

  def DATAMINE_find_multiplier_effect
    
    data = Date.parse("2005-01-01").upto_bymonth_array(Date.today >> 1).map do |month|
      [ month.to_s,                                                              # month
        self.campaigns.select { |camp| camp.live_at(month)}.size,                # campaigns
        month.customers_this_month.size - (month - 3).customers_this_month.size, # excess customers
        self.campaigns.select { |camp| camp.live_at(month)}.inject(0){ |sum,camp| sum + camp.customers.size} # directly attributable to campaign
      ]
    end
    
    data.select {|quad| quad[1] !=0 }.map {|quad| quad[3] == 0 ? 0 : quad[2] / quad[3]}.average
  end

  def UNIV_RESEARCH_core(stars)
    p = products 
    p = childCats.map(&:products).flatten if p.empty?
    p.select {|t| 
      (t.product_set_ordinal.nil? || t.product_set_ordinal == 1) &&
      ( ! t.avg_rating.nil? && t.avg_rating >= stars) && 
      t.display }.map { |t| t.product_set.nil? ?  t : t.product_set.products }.flatten
  end

  # useful for figuring what to put in a newly create university
  def UNIV_RESEARCH_all_fourstar_products_and_sequels
    UNIV_RESEARCH_core(4).map { |t|  t.name }
  end



end

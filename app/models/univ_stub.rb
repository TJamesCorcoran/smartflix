class UnivStub < Product

  attr_protected # <-- blank means total access

  belongs_to :university
  delegate :display_product, :to => :university

#  include AbTester

  # override base class

  def primary_category()
    return university.category
  end

  def price() 
    
    # used to be:
    #   different prices depending on AB test
    # now:
    #   test is concluded; deprecated (but keeping the routes alive for a while)
    #
    # REMOVE_AFTER: 1 Jan 2011

    #-----
    #     if session && ab_test(:univ_firstmonth_deal, session) == :free  
    #       0.00
    #     elsif session && ab_test(:univ_firstmonth_deal, session) == :fifty_percent  
    #       full_price / 2
    #     else
    #       full_price
    #     end
    #-----
    
    0.00
  end

  def full_price() university.subscription_charge_for_n(3)  end

  def purchase_price()    249.00  end
  def description() 
    return "Learn stuff" if Rails.env == "test"   # XYZFIX P4 - it might be better to just fix the fixtures


    "Learn #{ self.university.category.descriptionOrAlt } from the most
	 talented artists and craftsmen in the field.  Keep the DVDs as long as you want!" 
  end

  def days_backorder() 0 end

  def titles() university.videos end

  def description
    "#{university.name} is unlike anything you've seen before - it's " +
      "a complete program of DVDs from the most " +
      "talented artists and craftsmen in the field.  We ship you  " +
      "3 DVDs per month - keep them as long as you " +
      "want, with no late charges!  When you're ready for more, mail " +
      "those DVDs back to us, and we'll send you the next  " +
      "3 DVDs. " +
      "With exciting, informative, well shot videos from names like " +
      "#{ university.top_authors.map(&:name).to_sentence } that you can " +
      "keep as long as you want, the ability to cancel at any time, " +
      "and with a low monthly price of just  " +
      "#{ university.subscription_charge.currency }, this is a bargain that " +
      "you can't afford to miss! " 
    
  end

  def extra_custom_text_in_view?
    name == "Your Custom University"
  end

  def self.create_stub(univ)
    univ = univ.is_a?(University) ? univ : University.find(univ)

    author = Author.find_by_name("various")
    author ||= Author.create!(:name => "various") unless  ("production" == Rails.env )


    univstub = UnivStub.new(:name => univ.name,
                            :date_added => Date.today,
                            :author => author,
                            :minutes => 0,
                            :description => "",
                            :vendor => Vendor.find_by_name("Smartflix.com"),
                            :handout => nil,
                            :price => 0.00,
                            :display => true,
                            :virtual => true,
                            :purchase_price => 0.00,
                            :university_id => univ.id)
    # This is weird - if we just do this:
    #       univstub.categories.push( univ.category.id )
    # we get problems, because we try to reuse the same categories_products entry ?!?!?!
    # 
    # Maybe not worth entirely understanding and fixing right now; just work around.
    univstub.categories.push( Category.find_by_category_id(univ.category.category_id) )
    univstub.save!
  end

end

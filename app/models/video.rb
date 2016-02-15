class Video < Product

  has_many :upsell_offers
  validates_numericality_of :minutes

  #----------
  # customer search
  #----------
  # # XXXFIX P3: Need to have search look at prefixes too, by default
  # # (search for stemming with acts_as_ferret)
  # # XXXFIX P3: Search for <foo returns 600+ items and takes a long time...
  # acts_as_ferret(:fields =>
  #                { :listing_name => { :boost => 2.5 },
  #                  :name => { :boost => 2.0 },
  #                  :author_name => { :boost => 2.0 },
  #                  :description => { :boost => 1.0 }
  #                })


  # define_index do
  #   indexes :name, :sortable => true
  #   indexes :listing_name, :sortable => true
  #   indexes :author_name, :sortable => true
  #   indexes :description, :sortable => true
  # end


  def associated_universities
    categories.map(&:universities).flatten.uniq
  end

  def replacement_price
    purchase_price && purchase_price + 15.0 # $10 estimated shipping + $5 restocking
  end
  
  LATE_WEEKLY_BASE = 4.99
  
  def late_price
    return(LATE_WEEKLY_BASE)  if  purchase_price.nil? || purchase_price < 70
    return(LATE_WEEKLY_BASE + 2)  if purchase_price < 120
    return(LATE_WEEKLY_BASE + 4)
  end
  
  

end

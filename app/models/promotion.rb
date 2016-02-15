class Promotion < ActiveRecord::Base
  self.primary_key ="promotion_id"

  attr_protected # <-- blank means total access

  has_many :promotion_pages
  
  DEFAULT_STATUSES = ['minimized', 'full']
  AUDIENCES = ['all', 'new', 'existing']
  
  # Finds and returns all which are are "on" and which match the 'first_request' parameter.
  #  first_request should be boolean.
  #  Promotions with an audience of 'all' or 'new' will be return if first_request is true;
  #  'all' or 'existing' if it is false.
  def Promotion.find_all_for_audience( first_request )
    find(:all, :conditions => '`on` = 1').select{|p| p.for_audience?( first_request ) }
  end
  
  def ordered_pages
    promotion_pages.sort_by{|page| page.order}
  end
  
  def minimized_content
    tagline
  end
  
  def for_audience?( first_request )
    return audience == 'all' ||
           (first_request and audience == 'new') ||
           (!first_request and audience == 'existing')
  end

  def self.create_new(options)
    allowed = [:on, :name, :css, :default_status, :display_page,
               :sticky, :close_text, :minimize_text, :maximize_text,
               :next_page_text, :previous_page_text, :audience,
               :hide_next_on_last_page, :hide_previous_on_first_page,
               :ab_test_name, :pages, :display_for_which_urls_regexp]
    required = [:name, :pages, :display_for_which_urls_regexp]

    raise "required options = #{required.inspect}" if (required.to_set - options.keys.to_set).any?
    raise "allowed options = #{allowed.inspect}" if (options.keys - allowed).any?
    raise "one or more pages must be present" if options[:pages].empty?
    raise "page keys must be ints" if options[:pages].keys.detect { |key| ! key.is_a?(Integer) }

    promo = Promotion.create!(:on => options[:on] || true,
                              :tagline => options[:name],
                              :css => options[:css] || "",
                              :default_status => options[:default_status] || "full",
                              :display_page => options[:display_for_which_urls_regexp],
                              :sticky => options[:sticky] || true,
                              :hide_next_on_last_page => options[:hide_next_on_last_page] || true,
                              :hide_previous_on_first_page => options[:hide_previous_on_first_page] || true,
                              :close_button => options[:close_text] || "close",
                              :minimize_button => options[:minimize_text] || "minimize",
                              :maximize_button => options[:maximize_text] || "maximize",
                              :next_button => options[:next_page_text] || ">>",
                              :previous_button => options[:previous_page_text] || "<<",
                              :audience => options[:audience] || "all",
                              :ab_test_name => options[:ab_test_name])
    
    options[:pages].each_pair do | page_key, page_text | 
      PromotionPage.create!(:promotion => promo,
                           :order => page_key,
                           :content => page_text)
    end
    promo
  end
  
  protected
  
  def validate
    errors.add(:default_status, " must be #{DEFAULT_STATUSES.join(',')}") unless DEFAULT_STATUSES.include?(default_status)
    errors.add(:audience, " must be #{AUDIENCES.join(',')}") unless AUDIENCES.include?(audience)
  end
  
  
end

# To run:
#   bin/tvr_job.rb do adwords_smartflix
#


# How to add ads for a new class
# ------------------------------
#
# Your class needs to support a few methods.
#  1) have it include the module AdwordsUtil (below)
#  2) and then either 
#       a) supply headline(), lines_1(), and lines_2() methods that, and 
#              use the default triples() method, thus using all permutations 
#              of headline(), line1(), line2()
#       b) override the triples method to return triples that work well together, 
#              e.g.
#                  def triples()
#                       [  [ "123", "...456", "Burma-Shave" ],
#                          [ "ABC", "...DEF", "Burma-Shave" ] ]
#                  end
#  3) * create_adword_P()
#     * get_max_cpc()   5
#     * group_code()
#     * group_name()
#
# running:
#   1) bin/tvr_job.rb do adwords_smartflix
#
# debugging:
#   1) run the console
#   2) require 'smartflix_adwords'



# need to invoke classes to make them autload before redefining them
Category; Video; Author; ProductSet ; Vendor ; OtherAd; University; UnivStub


module AdWordsUtil
  def campaign_name()  "camp10-#{group_code}-#{(id / 1000) + 1}"  end

  def ct_code()         "camp10"                                  end
  def display_url()     "SmartFlix.com"                         end
  def url(google_id)    raise 'you need to implement this!'     end
  def entire_ad()       
    keywords = AdwordsKeyword.find_all_keywords(self)
    ret  = "create    = #{ create_adword_P ? "true" : "false"}\n"
    ret << "keywords (#{keywords.size})  = #{keywords.join(',')}\n"
    ret << "headlines(#{headlines.size}) = #{headlines.join(', ')}\n"
    ret << "lines_1   (#{lines_1.size}) = #{lines_1.join(', ')}\n"
    ret << "lines_2   (#{lines_2.size}) = #{lines_2.join(',')}\n"
    ret << "dispurl   = #{display_url}\n"
    ret << "----------\n"
  end

  # you can override this for your class, if you don't actually want the product
  def triples() 
    aa = headlines.select { |l| l && l.any? && l.size <= AdwordsEngine::MaxTitleLen }
    bb = lines_1.select { |l| l && l.any? && l.size <= AdwordsEngine::MaxDescriptionLen }
    cc = lines_2.select { |l| l && l.any? && l.size <= AdwordsEngine::MaxDescriptionLen }
    aa.cross(bb.cross( cc )).map(&:flatten)
  end


  # you can override this for your class
  def headlines()       [ "Rent videos!" ]                           end
  def lines_1()          [ "Save money on instructional videos." ]    end
  def lines_2()          [ "Rent online, free shipping!" ]            end


end

[ Category, Product, Author, ProductSet, Vendor, UnivStub, OtherAd, University ].each { |advertiseable| advertiseable.send(:include, AdWordsUtil)  }


# XYZ FIX P2: tests of this would be nice...
class UnivStub
  def best_description() university.category.good_human_name.singularize  end
  def description_verbs() university.category.description_verbs end
  def get_keyword_stubs 
    [ university.category.good_human_name ]
  end
  def get_keyword_generation_rules() 
    # university.category.get_keyword_stubs 
    ["learn %s",
#     "%s video",
#     "%s DVD",
#     "%s howto", "%s how-to", "%s how to",
#     "%s instruction",
#     "%s skill",
#     "%s tutorial",
#     "%s school",
#     "%s"
    ]
  end

  def create_adword_P() true   end
  def get_max_cpc()   100  end
  def group_code() "UNISTUB5" end
  def group_name() "#{group_code}-#{id}-#{name}"[0,AdwordsEngine::MaxGroupNameLen]  end

  def url(google_id)  "http://smartflix.com/store/video/#{id}?ct=#{ct_code}-ADID=#{google_id}"  end
  def display_url() 
    ret = "smartflix.com/#{university.name.gsub(/ /, '_')}"
    ret = "smartflix.com/#{university.name_short.gsub(/ /, '_')}" if ret.size > AdwordsEngine::MaxDescriptionLen
    ret = "smartflix.com" if ret.size > AdwordsEngine::MaxDescriptionLen
    ret
  end
  def headlines()
    raise "no best description" if best_description == ""
    headlines = [
                 "Learn #{ best_description} now",
                 "Learn #{ best_description} skills instantly",
                 "Learn #{ best_description} skills now",
                 "Learn #{ best_description} skills",
                 "Learn #{ best_description} today",
                 "Learn #{ best_description}",
                 "Learn the secret of #{ best_description} now",
                 "Learn the secret of #{ best_description}",
                 "Want to learn #{best_description}?",
#                 "#{ best_description} DVD school"
#                 "#{ best_description} made easy",
#                 "Better #{best_description} skills",
#                 "Do you know #{ best_description} secrets?",
#                 "Do you know these #{ best_description} secrets?",
#                 "Do you know these #{best_description} tips?",
#                 "Easy #{ best_description} tips",
#                 "Learn #{ best_description} instantly",
#                 "Learn the secret of #{ best_description} instantly",
                ]

    description_verbs.split(/[;,:]/).each do |verb|
      headlines += ["Want to learn how to #{verb}?",
#                    "Do you know how to #{ verb}?",
                    "Learn how to #{ verb}",
                    "Learn how to #{ verb} instantly",
                    "Learn how to #{ verb} now" ] 
    end if ! description_verbs.nil?
    
    headlines = headlines.select { |headline| headline.size <=  AdwordsEngine::MaxTitleLen}
    
    headlines = [ "#{best_description} DVDs" ] if headlines.empty?
    headlines = headlines.select { |headline| headline.size <=  AdwordsEngine::MaxTitleLen}
    
    headlines
  end
  def lines_1()          [ "#{university.name_short} will show you how" ]    end
  def lines_2()          [ "for just #{university.subscription_charge.currency} / month",
                         "Satisfaction 120% guaranteed." ]     end

end

class String
  def cruftless
    split.reject{ |word| word.match(/^(disc|disk|type|job|season|series|volume|part|vol|show|cd|i|ii|iii|iv|v|vi|vii|viii|[a-z]|an|in|the|for|with|on|of|#?[0-9]+)$/)}.join(" ").gsub(/[!]/,'')
  end
end

class Category
  def best_description() description.singularize  end
  def description_verbs() [] end    # FIX!!!


  def group_code()    "CAT"  end
  def url(google_id)  "http://smartflix.com/store/category/#{id}?ct=#{ct_code}-ADID=#{google_id}"  end
  def group_name()    "#{group_code}-#{"%0.4i" % id}-#{description.tr(" ", "-")}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc()   50  end
  def display_url()   "SmartFlix.com/#{best_description.gsub(/[:\/,&]/,'').gsub(/\s+/, '_')}"         end
  def create_adword_P() advertiseP   end

  def get_keyword_stubs
    keywords = [ best_description ]
    keywords << self.keywords.split(/[;,:]/) if ! self.keywords.nil?
    keywords << description_verbs.split(/[;,:]/) if ! description_verbs.nil?
    keywords.flatten.reject{ |kw| kw.match(/^\s*$/)}.map{|kw| kw.strip }
  end

  def get_keyword_generation_rules
    # XYZFIX P4: anytime there's a possessive, duplicate the keyword and put in the non-possessive noun
    # e.g. "Jim's airbrushing" --> [ "Jim airbrushing" , "Jim's airbrushing" ]
    #
    keyword_rules = ["learn %s",
                     "%s video",
                     "%s DVD",
                     "%s howto", "%s how-to", "%s how to",
                     "%s instruction",
                     "%s tutorial",
                     "%s skill",
                     "%s school",
                     "%s"
                    ]
    keyword_rules
  end

  def headlines
    headlines = ["Better #{best_description} skills",
                 "Do you know #{ best_description} secrets?",
                 "Do you know these #{ best_description} secrets?",
                 "Do you know these #{best_description} tips?",
                 "Easy #{ best_description} tips",
                 "Killer #{ best_description} tips",
                 "Learn #{ best_description}",
                 "Learn #{ best_description} instantly",
                 "Learn #{ best_description} today",
                 "Learn #{ best_description} now",
                 "Learn #{ best_description} skills",
                 "Learn #{ best_description} skills instantly",
                 "Learn #{ best_description} skills now",
                 "Learn the secret of #{ best_description}",
                 "Learn the secret of #{ best_description} instantly",
                 "Learn the secret of #{ best_description} now",

# XYZFIX P2: more ideas, commented out for now 
#                  "Rent #{ best_description} DVDs",
#                  "Rent #{ best_description} DVDs instantly",
#                  "Rent #{ best_description} DVDs now",
#                  "Rent #{ best_description} videos",
#                  "Rent #{ best_description} videos instantly",
#                  "Rent #{ best_description} videos now",
#                  "The secret to #{ best_description} ",
#                  "The secret to #{ best_description} is here",
#                  "Want better #{best_description} skills?",
#                  "Need better #{ best_description} skills?",
                 "Want to learn #{best_description}?",
                 "#{ best_description} made easy",
                 "#{ best_description} DVD school"]

    description_verbs.split(/[;,:]/).each do |verb|
      headlines += ["Want to learn how to #{verb}?",
                    "Do you know how to #{ verb}?",
                    "Learn how to #{ verb}",
                    "Learn how to #{ verb} instantly",
                    "Learn how to #{ verb} now" ] 
    end if ! description_verbs.nil?
    
    headlines = headlines.select { |headline| headline.size <=  AdwordsEngine::MaxTitleLen}
    
    headlines = [ "#{best_description} DVDs" ] if headlines.empty?
    headlines = headlines.select { |headline| headline.size <=  AdwordsEngine::MaxTitleLen}
    
    headlines
  end

  def lines_1
    lines = [
             "Killer #{best_description} DVDs for you.",
             "Killer how-to DVDs for you.",
             "Save money on #{best_description} DVDs.",
             "Save money on how-to DVDs.",
             "Tons of #{best_description} DVDs for rent.",
             "Tons of #{best_description} DVDs.",
             "Tons of killer how-to DVDs.",

# XYZFIX P2: more ideas, commented out for now 
#              "World's best how-to DVDs.",
#              "World's best #{best_description} DVDs.",
#              "World's best how-to DVDs, delivered.",
#              "The perfect how-to DVD.",
#              "The perfect #{best_description} DVD.",
#              "We have the perfect #{best_description} DVD.",
#              "We have #{best_description} DVDs.",
#              "How-to DVDs delivered.",
#              "#{best_description} DVDs delivered.",
#              "Expert instruction on DVD.",
#              "Expert #{best_description} instruction on DVD.",
#              "Expert #{best_description} info on DVD.",
            ]
    
    lines.select { |line| line.size <=  AdwordsEngine::MaxDescriptionLen}
    
  end 
end

# XYZ FIX P2: Note that we can specify "exemptionRequestion" as a
# field when uploading - something to think about with the pharma
# rejections...
class Product
  def group_code()    "TIT"  end
  def url(google_id)    "http://smartflix.com/store/video/#{id}/&ct=#{ct_code}-ADID=#{google_id}"  end

  # Written in 2011, after the old fully-automated approach below has been dormant for several years.
  # Goal: kick out some keywords that we can put in manually
  def get_keyword_stubs() 
    stubs = name.downcase.split(/ for |[\.\/#&,:;\+]/)
    # XYZ FIX P3: we'd like to do this for AK-47, M-1, Ruger 10/22
    stubs = stubs.map{ |stub| stub.match(/ar-15|m-1|ak-47/) ? stub : stub.split(/\-/) }.flatten
    stubs = stubs.map { |stub| stub.cruftless }.map(&:strip)
    stubs.reject{ |stub| stub.match(/^(\s*|advanced|pro tips|techniques|projects)$/) }
  end
  def get_keyword_generation_rules()    format =   ['%s video', '%s DVD', "%s howto", "%s how-to", "%s how to", "%s instruction", "%s skill"]  end
  def group_name()    "#{group_code}-#{"%0.4i" % id}-#{name.tr(" &", "--")}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc()    50   end

  def display_url()   
    url = "SmartFlix.com/#{name.cruftless.gsub(/[:\/,&]/,'').gsub(/\s+/, '_')}"
    url = categories.first.display_url if url.size > AdwordsEngine::MaxDescriptionLen && ! categories.empty?
    url = "SmartFlix.com" if url.size > AdwordsEngine::MaxDescriptionLen
    url 
  end

  def create_adword_P
    return intelligent_display     if first_in_set_or_standalone
    return ( name.cruftless != base_product.name.cruftless) 
  end

  # XYZ FIX P4: we could kick out a variety of headlines here, and create multiple ads...
  def headlines
    headline = "Rent #{name.cruftless} DVDs."
    headline = "#{name.cruftless} DVDs." if (headline.length > AdwordsEngine::MaxTitleLen)
    headline = "#{name.cruftless}." if (headline.length > AdwordsEngine::MaxTitleLen)
    return [ headline ] if headline.length < AdwordsEngine::MaxTitleLen
    
    # XYZFIX P4: try the author's name before we give up and use category 
    headlines = self.categories.map(&:headlines).flatten.select{ |h| h.length <= AdwordsEngine::MaxTitleLen}
  end

end

# XYZ FIX P2: do something smart w multiple authors - right now we
# just choose not to run an ad at all (because it would be too long)
class Author
  def group_code()    "AUT"  end
  def url(google_id) "http://smartflix.com/store/author/#{id}/?ct=#{ct_code}-ADID=#{google_id}"  end
  def get_keyword_stubs() [ name ]  end
  def get_keyword_generation_rules() ['%s video', '%s videos', '%s DVD', '%s DVDs', '%s']  end
  def group_name() "#{group_code}-#{"%0.4i" % id}-#{name.tr(" ", "-")}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc() 50  end
  def create_adword_P() (! products.empty?) && advertiseP && (! headlines.empty?) && ! products.detect{ |product| product.intelligent_display }.nil?  end
  def headlines()
    headline = "Rent DVDs by #{name}"
    headline = name if headline.length > AdwordsEngine::MaxTitleLen
    return [] if headline.length > AdwordsEngine::MaxTitleLen
    [ headline]
  end
  def topics() 
    topics = ["how to", "instructional"]  
    topics << self.major_cat.description.downcase if ! self.major_cat.nil?
    topics
  end

  def display_url
    url = "SmartFlix.com/#{name.gsub(/\s+/, '_')}"
    url = major_cat.andand.display_url if url.size > AdwordsEngine::MaxDescriptionLen
    url = "SmartFlix.com" if url.nil? || url.size > AdwordsEngine::MaxDescriptionLen
    url
  end
  
  def lines_1
    lines = [
             "Save money on $topic $format.",
             "Killer $topic $format for you.",
             "Tons of killer $topic $format.",
             "World's best $topic $format.",
             "World's best $topic $format delivered.",
             "The perfect $topic $format.",
             "We have the perfect $topic $format.",
             "Expert $topic instruction $format.",
             "Expert $topic info $format."
            ].cross_format(topics, "$topic").cross_format(["DVDs", "videos"], "$format")
    
    lines.select { |line| line.size <=  AdwordsEngine::MaxDescriptionLen}
  end

    
  def lines_2()          [ "Rent online, free shipping!" ]           end


end

class ProductSet
  def group_code()    "SET"  end
  def group_name() "#{group_code}-#{"%0.4i" % id}-#{setText.tr(" &", "-")}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc() 50 end
  def get_keyword_stubs() first_title.get_keyword_stubs  end
  def get_keyword_generation_rules() first_title.get_keyword_generation_rules  end

  def url(google_id)
    tid = titles.sort_by { | tt| tt.ordinal }[0].id
    "http://smartflix.com/store/video/#{tid}/?ct=#{ct_code}-ADID=#{google_id}"
  end

  def create_adword_P
    return true  if ! titles.empty? && first_title.intelligent_display
    # @@logger.call "  **** not generating ad -  #{name} has display == 0!"
    return nil
  end


  # XYZ FIX P4: we could kick out a variety of headlines here, and create multiple ads...
  def headlines
    # start w the set name, then remove "the" from the front, "series" from the end
    setText.match(/^(the ?)?(.*?)( ?(series|set|vol.?|volume) *[0-9]*?)?$/)
    text = $2

    headline = "Rent #{text} DVDs"
    headline = "#{text} DVDs" if (headline.length > AdwordsEngine::MaxTitleLen)
    headline = "#{text}" if (headline.length > AdwordsEngine::MaxTitleLen)
    headline = nil if (headline.length > AdwordsEngine::MaxTitleLen)
    return [ headline ] if ! headline.nil?
    
    titles.sort_by { | tt| tt.ordinal }[0].categories[0].headlines.select { |headline| headline.length > AdwordsEngine::MaxTitleLen } 
  end

end

class Vendor
  def group_code()    "VEN"  end
  def group_name() "#{group_code}-#{"%0.4i" % id}-#{name.tr(" &", "-")}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc() 50 end
  def vendor_url_full() name.downcase.split("/").first.gsub(/^www./,"").gsub(/\/$/,"")  end
  def vendor_url_base() vendor_url_full.gsub(/\.(com|info)$/,"") end
  def get_keyword_stubs()   [vendor_url_full, vendor_url_base] end
  def get_keyword_generation_rules() ["%s", "%s videos", "%s how to"] end
  def url(google_id)    "http://smartflix.com/store/category/108/Arts-Crafts?ct=#{ct_code}-ADID=#{google_id}"  end
  def create_adword_P() advertiseP && ! headlines.empty?  end
  def headlines()
    # XYZ FIX P2: we give up too easilly here - bigcermicstore.com, etc.
    ["Rent $url DVDs"].cross_format([vendor_url_base, vendor_url_full], "$url").select { |line| line.size <=  AdwordsEngine::MaxTitleLen}
  end
end

class University
  def group_code()    "UNI"  end
  def group_name() "#{group_code}-#{"%0.4i" % id}-#{name.tr(" &", "-")}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc() 50 end
  def url(google_id)    "http://#{primary_domain}?ct=#{ct_code}-ADID=#{google_id}"  end
  
  def get_keyword_stubs() OtherAd.find(:all, :conditions => "university_id = #{id}").first.keywords.split(';')   end
  def get_keyword_generation_rules() ["%s"] end
  def create_adword_P() true  end
  def triples() OtherAd.find(:all, :conditions => "university_id = #{id}").map{ |oa| [ oa.headline, oa.line_1, oa.line_2] }        end
  def display_url()     primary_domain                       end
  
  def get_keywords_modern
    puts [
          "learning #{name_verb} ",
          "#{name_verb} ",
          "#{name_verb} intro",
          "#{name_verb} introduction",
          "#{name_verb} tutorial",
          "#{name_verb} how-to",
          "#{name_verb} howto",
          top_authors.map(&:name)].flatten.join("\n")
  end
  
  def headlines()    univ_stub.headlines  end

end


class OtherAd
  def group_code()    "OAD"  end
  def group_name() "#{group_code}-#{id}"[0,AdwordsEngine::MaxGroupNameLen]  end
  def get_max_cpc() self.maxCPC * 100 end
  def get_keyword_stubs() self.keywords.split(";").map(&:strip) end
  def get_keyword_generation_rules() ["%s"] end
  def url(google_id)    "#{self.base_url}/?ct=#{ct_code}-ADID=#{google_id}"  end
  def create_adword_P() self.advertiseP end
  def display_url()     "SmartFlix.com"                         end
  def headlines()     headline.split(";").map(&:strip) end
end


class SmartflixAdwords

  # feel free to reset this!
  # call it thusly: SmartflixAdwords.@@logger.call("output")
  @@logger = method(:puts)   
  cattr_accessor :logger

  def update_to_google
    sandboxP = ! (Rails.env == "production")

    email            = 'admin_google@smartflix.com'
    password         = 'SMARTGOOGLE'
    error_count      = 0
    
    SOAP::RPC::Proxy.verboseP = true
    SOAP::RPC::Proxy.soap_error_callback = lambda do |x| 
      @@logger.call "faultstring == #{x.faultstring.text}"
      if sandboxP && x.faultstring.text.match(/Your client accounts may not exist/)
        AdwordsEngine.recover_after_new_sandbox(email, password)
        @@logger.call "****************************************"
        @@logger.call "Google claims no client emails.  In sandbox mode.  Ran recover_after_new_sandbox()."
        @@logger.call "Wait 5 minutes, then try again."
        @@logger.call "   - XYZ"
        @@logger.call "****************************************"
        exit
      end
    end
    
    dollars = 100
    AdwordsEngine.new(:daily_budget=> dollars * 100, 
                      :sandbox => sandboxP,
                      :email            => email,
                      :password         => password,
                      :developerToken   => 'tUV0B-bUIjBwGWTLgq1sKA',
                      :applicationToken => '3vFRMLDl5x4IrEcwwe3TbQ')  
    
    AdwordsKeyword.ignoreSuggestionsP = true
    
    items = []
#     items += Video.find(    :all,  :order => 'titleID')
#     items += ProductSet.find( :all,  :order => 'setID'  )
#     items += Category.find( :all,  :order => 'catID'  )
#     items += Author.find(   :all,  :order => 'authorID')
#     items += Vendor.find(   :all,  :order => 'vendorID'  ) 
#     items += OtherAd.find(  :all, :conditions => "ISNULL(university_id)")
    items +=  UnivStub.find(:all) 
#      items += [ UnivStub.find_by_name("Welder University"),
#                 UnivStub.find_by_name("Blacksmith University"),
#                 UnivStub.find_by_name("Oil Painting University")
# ]
    
#    items = items[0,2]
    
    success_count = 0
    errors = []
    
    items.each do |item|
      @@logger.call "==== #{item.group_name}"
      
#      begin
        AdwordsAd.create_if_needed(item)
        success_count += 1
#       rescue Interrupt, StandardError => e
#         errors << "#{item.class}, #{item.id}"
#         @@logger.call "\n*** Error: #{e}\n"
#         @@logger.call "BACKTRACE: " + e.backtrace.join("\nBACKTRACE: ")
#         @@logger.call e.inspect
#         error_count += 1
#         exit if error_count > 10
#       end
    end
    @@logger.call "Success: #{success_count}"
    @@logger.call "Fail:    #{errors.size}"
    @@logger.call "Errors:  \n" + (errors.empty? ? "<none>" : "*   #{errors.join("\n*   ")}")
    end
end

class AdwordsAd
  def customers 
    Origin.find(:all, :conditions => "first_uri like '%gac%ADID%'").select { |origin| 
      id == origin.first_uri.match(/gac.*-ADID=([0-9]+)/)[1].to_i
    }.map(&:customer)
  end
  
  def self.origins(begindate = Date.today, enddate = Date.today)
    begindate = Date.parse(begindate) if begindate.class == String
    enddate   = Date.parse(enddate)   if enddate.class == String
    Origin.find(:all, :conditions => "first_uri like '%gac%ADID%'").select{ |origin| 
      # ugly,but DateTime.to_date is broken in old rails
      origin.railscart_updated_at.to_time.to_date >= begindate &&
      origin.railscart_updated_at.to_time.to_date <= enddate
    }
  end

  def self.ads(begindate = Date.today, enddate = Date.today)
    origins(begindate, enddate).map(&:adwords_ad)
  end

  def self.customers(begindate = Date.today, enddate = Date.today)
    origins(begindate, enddate).map(&:customer)
  end

  def self.revenue(begindate = Date.today, enddate = Date.today)
    customers(begindate, enddate).sum(&:revenue)
  end
end

class AdwordsGroups
  def customers 
    adwords_ads.map(&:customers).flatten
  end
end

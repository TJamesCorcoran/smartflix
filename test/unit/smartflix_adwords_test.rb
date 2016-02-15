require 'test_helper'
# require 'date'
# # to use:
# #     1) rake db:test:prepare
# #     2) ruby test/unit/order_test.rb

# require 'smartflix_adwords'


# class SmartflixAdwordsTest < ActiveSupport::TestCase
#   # Load up all the fixtures
#   fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
#   fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })
  
#   def test_nothing
#     # we're not using adwords now, so ignore this
#   end
  
#   def foo_remove_title_cruft  
#     tt = Product.new(:name => "advanced lathe work disk 3")
#     stubs = tt.get_keyword_stubs.to_set
#     gold = ["advanced lathe work"].to_set
#     assert_equal(gold,stubs, "drop numbers and words like 'disk' (part 1) ")

#     tt = Product.new(:name => "advanced lathe work volume")
#     stubs = tt.get_keyword_stubs.to_set
#     gold = ["advanced lathe work"].to_set
#     assert_equal(gold,stubs, "drop numbers and words like 'disk' (part 2) ")

#     tt = Product.new(:name => "working on cars with tools")
#     stubs = tt.get_keyword_stubs.to_set
#     gold = ["working cars tools"].to_set
#     assert_equal(gold,stubs, "drop useless words like 'of' and 'the' ")

#     tt = Product.new(:name => "hunting snarks / the vorpal blade - the boojum tree")
#     stubs = tt.get_keyword_stubs.to_set
#     gold = ["hunting snarks", "vorpal blade", "boojum tree"].to_set
#     assert_equal(gold,stubs, "split on slashes and dashes")

#     tt = Product.new(:name => "ar-15 style stuff : m-16 style stuff : AK-47 style stuff")
#     stubs = tt.get_keyword_stubs.to_set
#     gold = ["ar-15 style stuff", "m-16 style stuff", "ak-47 style stuff"].to_set
#     assert_equal(gold,stubs, "split on dashes, but don't split 'ar-15' or 'm-1'")
#   end
  
#   def foo_category_best_description  
#     cc = Category.new(:description => "glassworking")
#     assert_equal("glassworking", cc.best_description, "base case of best_description")

# # XYZFIX P2: this feature never got finished
# #
# #    cc = Category.new(:description => "glassworking")
# #    assert_equal("glass", cc.best_description, "base case of best_description - also, singularize shouldn't distort 'glass'")
# #
# #    cc = Category.new(:description => "making toys")
# #    assert_equal("toy", cc.best_description, "singularize")
#   end

#   def foo_category_ads  
#     cc = Category.new(:description => "making toys")

# #  XYZFIX P2: this feature never got finished
# #    # headlines
# #    headlines_gold = ["Better toy skills", "Do you know toy secrets?", "Easy toy tips", "Killer toy tips", "Learn toy", "Learn toy instantly", "Learn toy today", "Learn toy now", "Learn toy skills", "Learn toy skills now", "Learn the secret of toy", "Want to learn toy?", "toy made easy", "toy DVD school"].to_set
# #    assert_equal(headlines_gold, cc.headlines.to_set,   "cat: headlines")    
# #    
# #    # line 1
# #    line1_gold = ["Killer toy DVDs for you.", "Killer how-to DVDs for you.", "Save money on toy DVDs.", "Save money on how-to DVDs.", "Tons of toy DVDs for rent.", "Tons of toy DVDs.", "Tons of killer how-to DVDs."].to_set
# #    assert_equal(line1_gold, cc.lines_1.to_set,   "cat: line_1")    

#     # line 2
#     line2_gold = ["Rent online, free shipping!"].to_set
#     assert_equal(line2_gold, cc.lines_2.to_set,   "cat: line_2")    

#     # disp url
#     assert_equal("SmartFlix.com/making_toy", cc.display_url,   "cat: display_url")

#     # keywords (basic ... advanced override in db)
#     keyword_stubs_gold = ["making toy"].to_set
#     assert_equal(keyword_stubs_gold, cc.get_keyword_stubs.to_set,   "cat: keyword_stubs")    

#     cc = Category.new(:description => "making toys", :keywords =>"puzzles; games, amusements : diversions")
#     keyword_stubs_gold = ["making toy", "puzzles", "games", "amusements", "diversions"].to_set
#     assert_equal(keyword_stubs_gold, cc.get_keyword_stubs.to_set,   "cat: keyword_stubs")    

#   end

#   def foo_title_ads  
#     tt = Product.new(:name => "making toys - advanced toymaking vol 3")

#     # headlines
#     headlines_gold = [].to_set
#     assert_equal(headlines_gold, tt.headlines.to_set,   "title: headlines")    
    
#     # line 1
#     line1_gold = ["Save money on instructional videos."].to_set
#     assert_equal(line1_gold, tt.lines_1.to_set,   "title: line_1")    

#     # line 2
#     line2_gold = ["Rent online, free shipping!"].to_set
#     assert_equal(line2_gold, tt.lines_2.to_set,   "title: line_2")    

#     # disp url
#     assert_equal("SmartFlix.com", tt.display_url,   "title: display_url")

#     # keywords (basic ... advanced override in db)
#     keyword_stubs_gold = ["making toys", "advanced toymaking"].to_set
#     assert_equal(keyword_stubs_gold, tt.get_keyword_stubs.to_set,   "title: keyword_stubs")    

    
    
#     # disp url - if a category is present, use that
#     cc = Category.new(:description => "Santa Stuff")
#     tt = Product.new(:name => "making toys - advanced toymaking vol 3")
#     tt.categories << cc
#     assert_equal("SmartFlix.com/Santa_Stuff", tt.display_url,   "title: display_url")
#   end

#   def foo_title_ads_decision_to_create  
#     tt = products(:dogstar_title)
#     assert( ! tt.create_adword_P, "no copies")

#     tt = products(:catstar_title)

#     assert( tt.create_adword_P, "1 copy - yes")    

#     tt = products(:frogstar_title)
#     assert( ! tt.create_adword_P, "1 copy in stock, dead - no")    

#     tt = products(:toadstar_title)
#     assert( ! tt.create_adword_P, "1 copy out of stock, live - no")    

#     tt = products(:fishstar_title)
#     assert( tt.create_adword_P, "first in set, list indiv titles")    

#     tt = products(:squidstar_title_1)
#     assert( tt.create_adword_P, "first in set, list indiv titles")    

#     tt = products(:squidstar_title_2)
#     assert( tt.create_adword_P, "second in set, list indiv titles, products(2) != products(1) ")    

    
#   end
  
#   def foo_author_ads  
#     cc = Category.new(:description => "Starship Stuff")
#     tt = Product.new(:name => "Galactica repairs")
#     tt.categories << cc
#     aa = Author.new(:name => "Bill Adama")
#     aa.products << tt
    
#     # headlines
#     headlines_gold = ["Rent DVDs by Bill Adama"].to_set
#     assert_equal(headlines_gold, aa.headlines.to_set,   "author: headlines")    
    
#     # line 1
#     line1_gold = ["World's best starship stuff videos.",
#                   "World's best how to DVDs.",
#                   "Save money on how to DVDs.",
#                   "Expert instructional info videos.",
#                   "Expert instructional info DVDs.",
#                   "The perfect instructional videos.",
#                   "Tons of killer how to videos.",
#                   "Save money on starship stuff DVDs.",
#                   "Expert how to info videos.",
#                   "The perfect how to videos.",
#                   "World's best how to DVDs delivered.",
#                   "World's best instructional videos.",
#                   "Expert how to info DVDs.",
#                   "We have the perfect how to DVDs.",
#                   "The perfect instructional DVDs.",
#                   "Tons of killer instructional DVDs.",
#                   "Expert starship stuff info videos.",
#                   "World's best instructional DVDs.",
#                   "World's best how to videos.",
#                   "Killer how to DVDs for you.",
#                   "The perfect starship stuff DVDs.",
#                   "Killer starship stuff DVDs for you.",
#                   "Save money on instructional videos.",
#                   "Expert starship stuff info DVDs.",
#                   "Killer how to videos for you.",
#                   "The perfect starship stuff videos.",
#                   "The perfect how to DVDs.",
#                   "Tons of killer how to DVDs.",
#                   "Save money on instructional DVDs.",
#                   "Expert how to instruction videos.",
#                   "We have the perfect how to videos.",
#                   "World's best starship stuff DVDs.",
#                   "Tons of killer starship stuff DVDs.",
#                   "Killer instructional DVDs for you.",
#                   "Save money on how to videos.",
#                   "Expert how to instruction DVDs."].to_set
#     assert_equal(line1_gold, aa.lines_1.to_set,   "author: line_1")    

#     # line 2
#     line2_gold = ["Rent online, free shipping!"].to_set
#     assert_equal(line2_gold, aa.lines_2.to_set,   "author: line_2")    

#     # disp url - uses the name
#     assert_equal("SmartFlix.com/Bill_Adama", aa.display_url,   "author: display_url")

#     # disp url - use category if author name is too long
#     aa.name = "Bill-Lots-Of-Middle-Names Adama"
#     assert_equal("SmartFlix.com/Starship_Stuff", aa.display_url,   "author: display_url")
#     aa.name = "Bill Adama"
    
#     # keywords
#     keyword_stubs_gold = ["Bill Adama"].to_set
#     assert_equal(keyword_stubs_gold, aa.get_keyword_stubs.to_set,   "author: keyword_stubs")    

#   end
  
#   def foo_vendor_ads  
#     vv = Vendor.new(:name => "www.MetalInfo.com")
    
#     # headlines
#     headlines_gold = ["Rent metalinfo.com DVDs", "Rent metalinfo DVDs"].to_set
#     assert_equal(headlines_gold, vv.headlines.to_set,   "vendor: headlines")    
    
#     # line 1
#     line1_gold = ["Save money on instructional videos."].to_set
#     assert_equal(line1_gold, vv.lines_1.to_set,   "vendor: line_1")    

#     # line 2
#     line2_gold = ["Rent online, free shipping!"].to_set
#     assert_equal(line2_gold, vv.lines_2.to_set,   "vendor: line_2")    

#     # disp url - uses the name
#     assert_equal("SmartFlix.com", vv.display_url,   "vendor: display_url")

#     # keywords
#     keyword_stubs_gold = ["metalinfo.com", "metalinfo"].to_set
#     assert_equal(keyword_stubs_gold, vv.get_keyword_stubs.to_set,   "vendor: keyword_stubs")    

#   end
  
#   def foo_other_ads  
#     oo = OtherAd.new(:headline => "first ; second", 
#                      :line_1 => "Save money on instructional videos.",
#                      :line_2 => "Rent online, free shipping!",
#                      :keywords => "aa ; bb")

#     # headlines
#     headlines_gold = ["first", "second"].to_set
#     assert_equal(headlines_gold, oo.headlines.to_set,   "other: headlines")    
    
#     # line 1
#     line1_gold = ["Save money on instructional videos."].to_set
#     assert_equal(line1_gold, oo.lines_1.to_set,   "other: line_1")    

#     # line 2
#     line2_gold = ["Rent online, free shipping!"].to_set
#     assert_equal(line2_gold, oo.lines_2.to_set,   "other: line_2")    

#     # disp url - uses the name
#     assert_equal("SmartFlix.com", oo.display_url,   "other: display_url")

#     # keywords
#     keyword_stubs_gold = ["aa", "bb"].to_set
#     assert_equal(keyword_stubs_gold, oo.get_keyword_stubs.to_set,   "other: keyword_stubs")    

#   end

  
# end

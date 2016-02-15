require File.dirname(__FILE__) + '/../test_helper'
require 'store_controller'

# Re-raise errors caught by the controller.
class StoreController; def rescue_action(e) raise e end; end

class StoreControllerTest < ActionController::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  def setup
    @controller = StoreController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  # Index doesn't do much, should return success
  def test_index    
    get :index
    assert_response :success
    assert_template 'index'
  end

  # Test category, with valid category IDs (both leaf and non-leaf)
  def test_category_valid_1    
    get :category, :id => 1, :name => 'Category1'
    assert_response :success
    assert_template 'category'
  end
  def test_category_valid_2    
    get :category, :id => 2, :name => 'Category2'
    assert_response :success
    assert_template 'category'
  end

  # Test category, sending nil category ID and an invalid one
  def test_category_invalid_1
    get :category
    assert_redirected_to :controller => 'store'
    assert_equal "Category not found", flash[:message]
  end
  def test_category_invalid_2    
    get :category, :id => 1000
    assert_redirected_to :controller => 'store'
    assert_equal "Category not found", flash[:message]
  end

  # Test category, with valid category IDs (both leaf and non-leaf)
  def test_redirect_1    
    get :video, :id => 1, :name => 'XXX'
    assert_response 301
    assert_redirected_to :controller => 'store', :action=>'video', :id => 1, :name => "Product1"
  end

  # Test video, with valid ID
  def test_video_valid    
    get :video, :id => 1, :name => 'Product1'
    assert_response :success
    assert_template 'video'
  end

  # Test video, with an invalid ID
  def test_video_invalid_1    
    get :video
    assert_redirected_to :controller => 'store'
    assert_equal "Video not found", flash[:message]
  end
  def test_video_invalid_2    
    get :video, :id => 666
    assert_redirected_to :controller => 'store'
    assert_equal "Video not found", flash[:message]
  end

  # Test video, with an ID that's not the first in a set (should be redirected to first)
  def test_video_not_first_in_set    
    get :video, :id => 4
    assert_redirected_to :id => 5
  end

  # Test review, make sure it requires a login
  def test_review_not_logged_in    
    get :review, :id => 1
    assert_redirected_to :controller => 'customer', :action => 'login'
    assert_equal "Login is required", flash[:message]
  end


  # Test review, make sure it requires an unexpired login
  def test_review_expired_login    
    get :review, { :id => 1 }, { :customer_id => customers(:bob).id, :timestamp => (Time.now.to_i - 3600) }
    assert_redirected_to :controller => 'customer', :action => 'login'
    assert_equal "Your session has timed out, please login again", flash[:message]
  end

  # Test review, make sure it works ok when logged in
  def test_review_logged_in    
    get :review, { :id => 1 }, { :customer_id => customers(:bob).id, :timestamp => Time.now.to_i }
    assert_response :success
  end

  # Make sure the redirects for reviews work (when logged in)
  def test_review_redirects_logged_in_1    
    get :review, {}, { :customer_id => customers(:bob).id, :timestamp => Time.now.to_i }
    assert_redirected_to :controller => 'store'
    assert_equal 'Error, could not access review page', flash[:message]
  end
  def test_review_redirects_logged_in_2    
    get :review, { :id => 1000 }, { :customer_id => customers(:bob).id, :timestamp => Time.now.to_i }
    assert_redirected_to :controller => 'store'
    assert_equal 'Error, could not access review page', flash[:message]
  end

  # Test submitting a review, make sure it requires a login
  def test_review_submit_not_logged_in    
    post :review, :rating => { :rating => 3, :review => 'I thought this was really good, I would watch it again' }
    assert_redirected_to :controller => 'customer', :action => 'login'
    assert_equal "Login is required", flash[:message]
  end

  # Test submitting a review, logged in
  def test_review_submit_logged_in    

    rating = 3
    review = 'I thought this was really good, I would watch it again, it was better than Cats'

    post(:review,
         { :id => 3, :rating => { :rating => rating, :review => review } },
         { :customer_id => customers(:bob).id, :timestamp => Time.now.to_i })

    assert_redirected_to :controller => :store, :action => 'video', :id => 3, :name => "Product3"
    assert_equal "Thanks! The review should appear within one business day.", flash[:message]

    # Make sure it was actually stored
    stored_review = Product.find(3).reviews[0]
    assert_equal review, stored_review.review
    assert_equal rating, stored_review.rating

  end

  # Test search (just need to make sure it responds)
  def test_search    
    get :search, { :q => 'boats' }
    assert_response :success
    assert_template 'search'
  end

  # Test search with no search term (should respond with no results,
  # looks like success)
  def test_search_invalid_1    
    get :search
    assert_response :success
    assert_template 'search'
  end

  # Test search with a search term that throws an exception ((should
  # respond with no results, looks like success)
  def test_search_invalid_2    
    get :search, { :q => '[' }
    assert_response :success
    assert_template 'search'
  end

  # Test new items page
  def test_new  
    get :new
    assert_response :success
    assert_template 'new'
  end

  # Test filter that lets us check for first request
  def test_first_request    
    get :index
    assert_response :success
    assert(@controller.send(:first_request?))
    get :index
    assert_response :success
    assert_equal(false, @controller.send(:first_request?))
    get :index
    assert_response :success
    assert_equal(false, @controller.send(:first_request?))
  end

  # Test filter that redirects for clickthrough requests
  def test_redirect_clickthroughs    
    get :index, { :ct => 'test' }
    assert_redirected_to :controller => 'store', :action => :index 
    get :index, { :baz => 'bam', :ct => 'test', :foo => 'bar' }
    assert_redirected_to :controller => 'store', :action => :index , :baz => 'bam', :foo => 'bar'
  end

  # Test redirect to canonical URL of products, categories, and authors
  def test_canonical_redirect    
    get :video, :id => 1
    assert_redirected_to :controller => 'store', :action => 'video', :id => 1, :name => 'Product1'
    get :category, :id => 1
    assert_redirected_to :controller => 'store', :action => 'category', :id => 1, :name => 'Category1'
    get :author, :id => 1
    assert_redirected_to :controller => 'store', :action => 'author', :id => 1, :name => 'Arthur-Author'
  end
  
#  def test_affiliate_link_video    
#    @request.session[:customer_id] = 2
#    get :video, :id => 1
#    assert_match /Affiliate\slink\sto\sthis\sVideo/, @response.body
#  end
  
#   def test_affiliate_link_author    
#     @request.session[:customer_id] = 2
#     get :author, :id => 1
#     assert_match /Affiliate\slink\sto\sthis\sAuthor/, @response.body  
#   end
  
#   def test_affiliate_link_category    
#     @request.session[:customer_id] = 2
#     get :category, :id => 1
#     assert_match /Affiliate\slink\sto\sthis\sCategory/, @response.body  
#   end

#   def test_no_affiliate_link_video    
#     @request.session[:customer_id] = 1
#     get :video, :id => 1
#     assert_no_match /Affiliate\slink\sto\sthis\sVideo/, @response.body  
#   end
  
#   def test_no_affiliate_link_author    
#     @request.session[:customer_id] = 1
#     get :author, :id => 1
#     assert_no_match /Affiliate\slink\sto\sthis\sAuthor/, @response.body  
#   end
  
#   def test_no_affiliate_link_category    
#     @request.session[:customer_id] = 1
#     get :category, :id => 1
#     assert_no_match /Affiliate\slink\sto\sthis\sCategory/, @response.body  
#   end

  def test_contact_us    
    post :contact_us, :message => { :name => "Shmoe",
                                    :email => "foo@smartflix.com",
                                    :message => "Your service is great!  I love you!" }
    assert_equal 2, @emails.size
  end
end

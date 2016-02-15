require File.dirname(__FILE__) + '/../test_helper'


# Re-raise errors caught by the controller.
class Admin::InventoryController; def rescue_action(e) raise e end; end

class InventoryControllerTest < ActionController::TestCase

  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })



  def setup
    @controller = Admin::InventoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    Copy.destroy_all
    Inventory.destroy_all
    product = Product.find(:first)
    copies = (2001..2020).map { |n| Copy.create_with_id(:id=> n, 
                                                   :product => product,
                                                   :birthDATE => Date.today) }
  end

  # there was a bug: if a copy had status == 1 (live) and deathtype == nil (no death)
  # inventory would blow up.
  #
  # make sure that that bug is fixed.
  #
  def test_no_death_type_required     
    copy = Copy.find(2001)
    assert_equal(copy.death_type_id, nil)

    get :start

    assert_response :success 
    assert_template 'start'
    assert_equal(2001, assigns["inventory"]["startID"])

    post(:start, "inventory" => { "startID" => "2001", "endID" => "2005"})
    get :in_progress

    ret = post :scan_dvd, "barcode" => "2001"
    assert ret.body.match("2001 - here")
        
  end

  # when a DVD has a status of "lost in house", and we find it in the
  # course of inventory, it should be returned to inventory
  #
  def test_lost_dvds_are_recovered

    # preconds
    copy = Copy.find(2001)
    assert_equal(copy.death_type_id, nil)

    copy.mark_dead(DeathLog::DEATH_LOST_IN_HOUSE, "lost in house") 
    copy.reload
    assert(copy.death_type.name, "lost_in_house")

    # start inventory
    get :start
    assert_response :success 
    assert_template 'start'
    assert_equal(2001, assigns["inventory"]["startID"])

    post(:start, "inventory" => { "startID" => "2001", "endID" => "2005"})
    get :in_progress

    ret = post :scan_dvd, "barcode" => "2001"

    # test results
    copy.reload
    assert copy.live?
    # assert_equal(copy.death_type.name, "live")
        

  end


end

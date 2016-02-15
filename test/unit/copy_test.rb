require 'test_helper'

# to use:
#     1) rake db:test:prepare
#     2) ruby test/unit/copy_test.rb

class CopyTest < ActiveSupport::TestCase

  # Load up all the fixtures
  fixture_files = Dir[File.dirname(__FILE__) + '/../fixtures/*.yml']
  fixtures(*fixture_files.collect { |f| f.match(/([^\/]*)\.yml/)[1].to_sym })

  # Test marking a copy as dead
  def test_mark_dead
    # prep the test
    copies(:copy1).death_logs.each { |dl| dl.destroy}
    copies(:copy1).reload
    
    # let the test begin
    copies(:copy1).mark_dead(DeathLog::DEATH_DAMAGED, 'TEST NOTE')
    copies(:copy1).reload

    # Make sure the right things happened
    assert(!copies(:copy1).status?)
    assert_equal(DeathLog::DEATH_DAMAGED, copies(:copy1).death_type_id)
    assert_equal(1, copies(:copy1).death_logs.size)
    assert_equal(DeathLog::DEATH_DAMAGED, copies(:copy1).death_logs[0].newDeathType)
    assert_equal('TEST NOTE', copies(:copy1).death_logs[0].note)

    # Bring it back to life! (by hand)
    copies(:copy1).update_attributes(:status => true, :death_type_id => DeathLog::DEATH_NOT_DEAD)
    DeathLog.create(:newDeathType => DeathLog::DEATH_NOT_DEAD, :note => 'RESTORE', :copy => copies(:copy1))
    copies(:copy1).reload

    # Make sure the right things happened
    assert(copies(:copy1).status?)
    assert_equal(DeathLog::DEATH_NOT_DEAD, copies(:copy1).death_type_id)
    assert_equal(2, copies(:copy1).death_logs.size)
    assert_equal('RESTORE', copies(:copy1).death_logs[1].note)
    assert_equal('TEST NOTE', copies(:copy1).death_logs[0].note)

    # Kill it again, another way
    copies(:copy1).mark_dead(DeathLog::DEATH_LOST_IN_TRANSIT, 'TEST NOTE 2')
    copies(:copy1).reload

    # Make sure the right things happened
    assert(!copies(:copy1).status?)
    assert_equal(DeathLog::DEATH_LOST_IN_TRANSIT, copies(:copy1).death_type_id)
    assert_equal(3, copies(:copy1).death_logs.size)
    assert_equal(DeathLog::DEATH_LOST_IN_TRANSIT, copies(:copy1).death_logs[2].newDeathType)
    assert_equal('TEST NOTE', copies(:copy1).death_logs[0].note)
    assert_equal('TEST NOTE 2', copies(:copy1).death_logs[2].note)

  end

  def test_clean_delete
    # ID used everywhere in fixtures: 1000
    # expect failure: no vendor_order_log
    novol = copies(:novol_copy)
    res = novol.clean_delete
    successP = (res == true)
    assert_equal(false, successP)
    assert_equal("no vendor_order_log entries to cleanup", res)

    # ID used everywhere in fixtures: 1001
    # expect failure: last vendor_order_log was an order, not receipt of a new copy
    positivevol = copies(:lastvol_positive_copy)
    res = positivevol.clean_delete
    successP = (res == true)
    assert_equal(false, successP)
    assert_equal("last vendor_order_log entry was > 0", res)

    # ID used everywhere in fixtures: 1002
    # expect failure: no inventory_ordered
    noinvord = copies(:noinvord_copy)
    res = noinvord.clean_delete
    successP = (res == true)
    assert_equal(false, successP)
    assert_equal("no inventory_ordered to cleanup", res)

    # ID used everywhere in fixtures: 1003
    # expect failure: lineItems exist
    lis_exist = copies(:lis_exist_copy)
    res = lis_exist.clean_delete
    successP = (res == true)
    assert_equal(false, successP)
    assert_equal("line items exist for this copy", res)

    # ID used everywhere in fixtures: 1004
    # expect success
    success = copies(:success_copy)
    product = success.product
    copy_id = success.id
    old_inv_ordered = product.inventory_ordered.quant_dvd
    old_last_order = product.vendor_order_logs.sort_by{ |vo| vo.orderDate}.reverse[0].quant

    # test return code
    res = success.clean_delete
    successP = (res == true)
    assert_equal(true, successP)

    # test the actual changes that should have been made:
    #    inventory_ordered is increased by one
    #    last arrival batch is decreased by one
    #    copy no longer exists
    product.reload
    new_inv_ordered = product.inventory_ordered.quant_dvd
    new_last_order = product.vendor_order_logs.sort_by{ |vo| vo.orderDate}.reverse[0].quant
    new_copy = Copy.find(:all, :conditions => "copy_id = #{copy_id}")

    assert_equal(new_inv_ordered, old_inv_ordered + 1)
    assert_equal(new_last_order, old_last_order + 1) # note '+1' instead of '-1' because we track size of orders placed, and an arrival is a decrement on this
    assert_equal(0, new_copy.size )

    # XXX should test:
    #   * when the old last arrival was 1, and we decrement it to zero, it goes away
    #   * when copy is a zombie - no product exists for it

  end
  
  def test_return_to_stock
    tests = [ { :fixture => :return_to_stock_already_instock, :desired_status => 1},
              { :fixture => :return_to_stock_outstock,        :desired_status => 1},
              { :fixture => :return_to_stock_damaged,         :desired_status => 1},
            ]
    
    tests.each do | test|
      copy = copies(test[:fixture])
      copy.return_to_stock
      copy.reload
      
      assert(copy.inStock == 1, "failed to be instock for #{test[:fixture].to_s}")
      assert(copy.status == test[:desired_status], "status = #{test[:desired_status]} for #{test[:fixture].to_s}")
    end
    
  end
  
  # should a given copy be sent in an envelope or a box?
  def test_boxP
    # low price -> no box
    assert(copies(:nobox).boxP == false)

    # high price ->  box
    assert(copies(:box).boxP == true)

    # hostile ->  box
    assert(copies(:hostile).boxP == true)
  end
  
end

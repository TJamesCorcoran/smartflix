# Set up using the main rails testing infrastructure
Rails.env = 'test'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'test_help'

# Load our test schema
load(File.dirname(__FILE__) + "/schema.rb")

# We want to use transactional fixtures (rollback after every test)
class Test::Unit::TestCase
  self.use_transactional_fixtures = true
end

# Set up our test models
class WidgetQuantityUpdate < ActiveRecord::Base
end
class Widget < ActiveRecord::Base
  track_changes_on :quantity
end
class Arrival < ActiveRecord::Base
end
class Departure < ActiveRecord::Base
end
class GidgetQuantityUpdate < ActiveRecord::Base
end
class Gidget < ActiveRecord::Base
  track_changes_on :quantity, :allowed_references => [:arrival, :departure]
end
class DidgetChange < ActiveRecord::Base
end
class Didget < ActiveRecord::Base
  # Track changes is set up dynamically in a test to capture thrown exceptions
end


class ChangeTrackerTest < Test::Unit::TestCase

  def test_basic_tracking
    w = Widget.new
    assert w.respond_to?(:quantity_updates)
    assert w.quantity_updates.empty?
    w.quantity += 10
    w.save
    w.reload
    assert_equal(1, w.quantity_updates.size)
    assert_equal(10, w.quantity_updates.first.change)
    assert_equal(w, w.quantity_updates.first.widget)
  end

  def test_multiple_change_tracking
    w = Widget.new
    w.quantity += 10
    w.quantity -= 5
    w.quantity += 15
    w.save
    w.reload
    assert_equal(3, w.quantity_updates.size)
    assert_equal(10, w.quantity_updates[0].change)
    assert_equal(-5, w.quantity_updates[1].change)
    assert_equal(15, w.quantity_updates[2].change)
    assert_equal(w, w.quantity_updates.first.widget)
    assert_equal(w, w.quantity_updates.last.widget)
  end

  def test_change_tracking_with_references
    g = Gidget.new
    assert g.respond_to?(:quantity_updates)
    assert g.quantity_updates.empty?
    g.quantity += 10
    g.save
    g.reload
    assert_equal(1, g.quantity_updates.size)
    assert g.quantity_updates.first.respond_to?(:reference)
    assert_nil g.quantity_updates.first.reference
    a = Arrival.create
    g.set_quantity(g.quantity + 5, :reference => a)
    d1 = Departure.new
    g.decrement_quantity(7, :reference => d1)
    d2 = Departure.new
    g.increment_quantity(6, :reference => d2)
    g.save
    g.reload
    assert_equal(4, g.quantity_updates.size)
    assert_equal(10, g.quantity_updates[0].change_in_quantity)
    assert_equal(5, g.quantity_updates[1].change_in_quantity)
    assert_equal(-7, g.quantity_updates[2].change_in_quantity)
    assert_equal(6, g.quantity_updates[3].change_in_quantity)
    assert_equal(a, g.quantity_updates[1].reference)
    assert_equal(d1, g.quantity_updates[2].reference)
    assert_equal(d2, g.quantity_updates[3].reference)
    a.reload
    d1.reload
    d2.reload
    assert a.respond_to?(:gidget_quantity_update)
    assert_equal(g.quantity_updates[1], a.gidget_quantity_update)
    assert_equal(g.quantity_updates[2], d1.gidget_quantity_update)
    assert_equal(g.quantity_updates[3], d2.gidget_quantity_update)
  end

  def test_change_tracking_with_note
    g = Gidget.new
    g.set_quantity(g.quantity + 5, :note => 'ONE')
    g.decrement_quantity(7, :note => 'TWO')
    a = Arrival.create
    g.increment_quantity(6, :reference => a, :note => 'THREE')
    g.save
    g.reload
    assert_equal(3, g.quantity_updates.size)
    assert_equal(5, g.quantity_updates[0].change_in_quantity)
    assert_equal(-7, g.quantity_updates[1].change_in_quantity)
    assert_equal(6, g.quantity_updates[2].change_in_quantity)
    assert_equal('ONE', g.quantity_updates[0].note)
    assert_equal('TWO', g.quantity_updates[1].note)
    assert_equal('THREE', g.quantity_updates[2].note)
    assert_equal(a, g.quantity_updates[2].reference)
  end

  def test_change_tracking_with_custom_names

    # First make sure certain errors are raised if names are confusing
    assert_raise(NameError) do
      Didget.track_changes_on :quantity, :allowed_references => [:arrival]
    end
    assert_raise(TrackingColumnNotFound) do
      Didget.track_changes_on :quantity, :tracked_by => :didget_changes, :allowed_references => [:arrival]
    end
    assert_raise(ReferenceColumnNotFound) do
      Didget.track_changes_on :quantity, :tracked_by => :didget_changes, :tracking_column => :difference,
                              :allowed_references => [:arrival]
    end

    Didget.track_changes_on :quantity, :tracked_by => :didget_changes, :tracking_column => :difference,
                            :tracking_reference_columns => :reference, :allowed_references => [:arrival]
    d = Didget.new
    assert d.respond_to?(:quantity_updates)
    assert d.quantity_updates.empty?
    d.quantity += 20
    d.quantity -= 10
    d.save
    d.reload
    assert_equal(2, d.quantity_updates.size)
    a = Arrival.new
    d.set_quantity(d.quantity - 7, :reference => a)
    d.save
    d.reload
    assert_equal(3, d.quantity_updates.size)
    assert_equal(-7, d.quantity_updates[2].difference)
    assert_equal(a, d.quantity_updates[2].reference)

    assert_raise(ReferenceNotAllowed) do
      d.set_quantity(d.quantity - 7, :reference => d)
    end

  end
  
end

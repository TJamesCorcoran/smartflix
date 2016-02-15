Overview
--------

If you have a table X, and on it you have a field Y that changes over
time, you'd like to have a historical record.

The historical record would ideally be instrumented with pointers.

If your bank account starts with $100 and ends at $200, not only do
you want to see that there 5 transactions on certain dates, but you
also want to be able to see what those transactions were.

We introduce:

   * a new table called X_Y_updates
   * ...which has pointers to other events

Thus, for a given X (say, a bank account) you can get all the changes
to a given Y (say, balance), and each update points to more information.

Further, parts of creating entries in X_Y_updates is automatic.
(XYZFIX P3: need more information here!).

...

Core concept
------------

Each 'update' ** ALWAYS ** points to the item that has been updated, and 
** MAY ** point to the thing that is associated with the update.  E.g.

  Person[1].set_bodyweight(220)
  Person[1].set_bodyweight(220, :reference => Cheeseburger[12] )


getting a historical record
---------------------------

The change tracker tracks either DELTAs or VALUES.

If deltas have been stored, to get a historical record, you need to do
this:

  order = Customer.xyz.univ_orders.first
  changes = order.univ_dvd_rate_updates
  changes = changes.map { |ch| { :created_at => ch.created_at, :delta  => ch.univ_dvd_rate } }

  total = order.univ_dvd_rate
  history = []
  changes.reverse.each { |pair| total += pair[:delta] ;  history << {  :created_at => pair[:created_at], :univ_dvd_rate => total } }

simple installation
-------------------

1) migration like this, to track changes of orders.univ_dvd_rate:

    table_name = "orders"
    col_name = "univ_dvd_rate"

    updates_table_name = "#{table_name.singularize}_#{col_name}_updates"

    create_table updates_table_name do |t|

  	  t.integer :<class_name>_id  # this points to the object we're modifying
  	  t.integer :<col_name>       # this gives the new value of the object's value

      t.string  :note # <--- optional ; see below

      t.string  :reference_type    # these two will have values when 
      t.integer :reference_id     # you do a 'modify' with a reference,
                                 # and will be null otherwise

      t.timestamps
    end


	NOTE: you *** can ** track two changes in a single table.  See far
	far 

2) edit the model that we're tracking changes on

   either

      track_changes_on :university_dvd_rate, 
	  				   :allowed_references => [:foo, :bar],  # to reference records responsible for each change
					   :store_type => :absolute              # :delta by default
   or

      track_changes_on :university_dvd_rate, :allowed_references => [], :tracking_reference_columns => [] # to NOT reference records responsible for each change

3) create new model to hold updates

      app/models/<tracked_table_singular>_<tracked_variable>_update.rb

	  class QuantityOrderedUpdate < ActiveRecord::Base
	    belongs_to :reference, :polymorphic => true
		belongs_to :quantity
	  end

  No need to make your tracked class know about this - it gets it
  automatically via the "track_changes_on" directive.
   

4) in places where we want to alter the tracked variable, we need to
use one of the three generated functions

	set_<foo>(val,  [ :reference => X], [ :note => Y ])  # note that 'note' argument is only allowed if the tracking table has a 'note' col
    increment_<foo>([ :reference => X], [ :note => Y ])  # as above
    decrement_<foo>([ :reference => X], [ :note => Y ])  # as above

    **** NOTE! must call .save!() after this!!!

To continue the above example, if we were extending class "Order" /
table "orders" to track changes to univ_dvd_rate, we'd have these three functions:

    set_univ_dvd_rate()
    increment_univ_dvd_rate()
    decrement_univ_dvd_rate()


    which can be used like this:

       increment_univ_dvd_rate(12)

   or this

       increment_univ_dvd_rate(12, :reference => foobar)

    
5) alter the data

    o = Order.new
    o.set_univ_dvd_rate(3)
    o.save!                     # <=============   UTTERLY CRITICAL !!!

6) view the historical deltas

    ( NOTE that deltas are stored, not actual values)

	  o.univ_dvd_rate_updates

    or
 
      o.univ_dvd_rate_updates.map(&:univ_dvd_rate)

    or gather the time sequence

      current = o.univ_dvd_rate
      o.univ_dvd_rate_updates.map(&:univ_dvd_rate).reverse.map { |delta| ret = current - delta ; current = ret ; ret }.reverse << o.univ_dvd_rate

complex case installation
----------------------------------------------------------

If you want to track changes on two or more columns in one table:


1) migration like this, to track changes of orders.univ_dvd_rate:


    create_table "people_updates" do |t|

  	  t.integer :<class_name>_id  # this points to the object we're modifying

  	  t.integer :height_updates   # 1st thing we track
  	  t.integer :weight_updates   # 2nd thing we track

      t.string  :note # <--- optional ; see below

      t.string  :reference_type    # these two will have values when 
      t.integer :reference_id     # you do a 'modify' with a reference,
                                 # and will be null otherwise

      t.timestamps
    end


2) edit the model that we're tracking changes on

    class People
      track_changes_on :height, 
	                   :allowed_references => [:foo, :bar],
					   :tracked_by => :people_updates,
					   :tracking_column => :height_updates

      track_changes_on :weight, 
	                   :allowed_references => [:foo],
					   :tracked_by => :people_updates,
					   :tracking_column => :weight_updates
	end

3) create new model to hold updates

   as in simple model, but pay attention to the name

4) in places where we want to alter the tracked variable, we need to use one of the three generated functions

   as in simple model

5) alter the data

    o = Order.new
    o.set_univ_dvd_rate(3)
    o.save!                     # <=============   UTTERLY CRITICAL !!!

6) view the historical deltas

    ( NOTE that deltas are stored, not actual values)

	  o.univ_dvd_rate_updates

    or
 
      o.univ_dvd_rate_updates.map(&:univ_dvd_rate)

    or gather the time sequence

      current = o.univ_dvd_rate
      o.univ_dvd_rate_updates.map(&:univ_dvd_rate).reverse.map { |delta| ret = current - delta ; current = ret ; ret }.reverse << o.univ_dvd_rate


Object model
------------

In HI we do:

   class Quantity < ActiveRecord::Base
      belongs_to :product, :polymorphic => true
      track_changes_on :instock, :allowed_references => [:indy_shipment_item,     :diamond_shipment_item,
                                                         :line_item]
      track_changes_on :ordered, :allowed_references => [:indy_order_item,        :diamond_order_item,
                                                         :indy_shipment_item,     :diamond_shipment_item,
                                                         :indy_cancellation_item, :diamond_cancellation_item]
   end

which gives us the object model:




		 		+------	DiamondCancellationItem.quantity_ordered_updates()
   	   	 		|
		 		+------	DiamondOrderItem.quantity_ordered_updates()
		 		|
		 		|		DiamondShipmentItem.quantity_instock_updates() 	------------+
		 		+------	DiamondShipmentItem.quantity_ordered_updates()				|
		 		|																	|
		 		+------	IndyCancellationItem.quantity_ordered_updates()				|
		 		|																	|
		 		+------	IndyOrderItem.quantity_ordered_updates()					|
		 		|																	|
		 *		|		IndyShipmentItem.quantity_instock_updates()	 ---------------+
		 | 	   	+------	IndyShipmentItem.quantity_ordered_updates()					|      *
		 |		|												 					|      |
		 |		|  	   	LineItem.quantity_instock_updates()		  ------------------+      |
 reference()    |                                                                   |      reference()
   	   	 ^		|																	|	   ^
		 |		|																	|	   |
		 |		|																	|	   |
	   	 |		|																	|	   |
				V																	V	   |
 QuantityOrderedUpdate <- ordered_updates() -+            +- instock_updates() --> QuantityInstockUpdate
         |                                   +- Quantity -+								   |
         |										 ^ ^  ^									   |
		 +----------------- quantity()  ---------+ |  +----------- quantity() -------------+
   	   	   	   	   	   	   	   	   	   	   	   	   |
												   V
                                                 Product
												   ^
												   |
 												   |
 												   V
                                          ... ConsignmentQuantity ...
											   	   .
												   .
												   .









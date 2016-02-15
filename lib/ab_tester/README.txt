Purpose
-------

AB testing infrastructure support.

Installation
------------

0) requirements

   install vendor/plugins/robot_test

0.5) in config/routes add

    AbTester.add_routes(binding, "admin")

1) Add the following in controllers/application_controller.rb

    require 'acts_as_abter_application_controller'           # <-- line 1

    class ApplicationController < ActionController::Base
        include AbTester                                        # <-- line 2
        acts_as_abter_application_controller                 # <-- line 3
        
        ...
    end

2) from your db/migrations dir, ln -s to

       vendor/plugins/db/migrations/create_abtests.rb

   then run migrations

3) in your models

   customer model: add

         require 'acts_as_abt_visitor'
         class Customer
              # give us ab_test_visitors(), ab_test_results_hash()
              acts_as_abt_visitor
         ...

   order model: append at end of file:

        AbTestResult
        class AbTestResult
          belongs_to :order
        end


4) in your customer login code, right after a customer logs in, say like this:

      @customer = Customer.authenticate(params)

add this:

      AbTester.map_customer_to_abtest(@customer, session)

5) any place you want to do an AB test, do this:

              <% if ab_test(:testname, session) == :foo -%>
                 foo
              <% elsif ab_test(:testname, session) == :bar -%>
                 bar
              <% end %>


6) in your checkout code, add this:

            ab_test_result(:increment, <testname>, order.value [ , order.id ] )

Create a new AB Test
--------------------

maybe use a migration.

    up:                                     
       AbTester.create_test(:tweet_in_nav,  
                             1,                         # flight
                             0.0,                       # base_result (???)
                             [:red, :blue, :green])     # options

    down:
       AbTester.destroy_test(:tweet_in_nav)

*** HINT: you might want to make the first one be  --> :default
    because that will get returned from time to time (robot detected, etc.)


Deactivate / reactivate a test
------------------------------

from console:

	 Abtester.deactivate_test(:tweet_in_nav)

	 Abtester.reactivate_test(:tweet_in_nav)

Find results
----------

	Abtester.get_stats(:tweet_in_nav)



Typical use
-----------

Client connects to server w blank slate.

Server needs to know "do I display icon in red or green?", calls

    color = ab_test(:red_or_green, {})
	# POST-CONDITION: 
	#   variable 'color' holds either
	#      * :default  (if it was a robot, etc.)
	#      * :red
	#      * :green  (in either case, a sym!)

	case color
	when :default, :red
	    # do thing A
 	when :green
	    # do thing B
	else
		raise "error: unknown color #{color}"
	end

result:
  1) AbTestVisitor is created for this customer (stored in db)
  2) id of that is stored in session
  3) a value for the red_or_green test is created (stored in db, accessible by visitor ID)

Server then uses result to display icon in appropriate color.

Client connects back to server a minute later w request for another page.

Server calls

    ab = ab_test(:red_or_green, {})

result:
  1) AbTestVisitor id is taken from session is created for this customer
  2) value for red_or_green test is taken from session


Stand-alone use (e.g. sending email)
------------------------------------

Server wants to send email to some customer

    Customers.all.each do |cust|
       HiMailer.fred(cust)
    end

    class Mailer
       def fred(customer)

           ab_hh = {:is_robot => false}
           ab_1 = ab_test(:univreco_mail, ab_hh)
           ab_2 = ab_test(:univreco_color, ab_hh)
           abtvid = ab_hh[:ab_test_visitor_id]

           puts "ab_1 = #{ab_1.inspect}"
           puts "ab_2 = #{ab_2.inspect}"
           puts "abtvid = #{abtvid}"

		   body        :customer => customer, :ab_1 => ab_1, :ab_2 => ab2, :abtvid => abtvid
        end     
    end  

	---- file: app/views/mailer/univ_reco.text.erb ----

		   if @ab_1 == :red
			   ...
		   else
			   ...
		   end

		   ...
		   url = "http://smartflix.com?abtvid=#{hh[:ab_test_visitor_id]}"

		   or

		   url = url_for(..., { :abtvid => @abtvid })
		   ...



Customer gets email (with proper colors from AB test) and proper URL
(with 'abtvid' set to visitor id).  Customer clicks it.

      http://smartflix.com?abtvid=123

then on the server function

   def acts_as_abter_application_controller()

in file

   lib/ab_tester/lib/acts_as_abt_application_controller.rb

gets called automagically because the application controller includes
AbTester.  The result is that the controller DTRT:

  1) AbTestVisitor is created for this customer (stored in db)
  2) ...then THROWN AWAY
  3) a value for the red_or_green test is created (stored in db)
  4) ...then THROWN AWAY

but importantly:

  5)    session[:ab_test_visitor_id] = params[:abtvid]

Then later, if the customer proceeds to checkout or takes another action

Result:
  * you get the value of the test

Concept: 'flights'
------------------
Every test in a given flight is guaranteed to be independant of all
the other tests in the same flight; tests in different flights will
not have this property.

Flights are offered as an option to work around the problem one sees
when running many tests: the most recently created tests will switch
options after groups of thousands of users, making it take a long time
to collect complete data; put the test in a newer flight (preferably
after ending all the tests in the older flight), and data can be
collected more quickly.

Model relationships
-------------------

                    <----(n)- AbTestOption
             AbTest                 ^
                    <------------+  |
                                 |  |
                                (n)(n)
                                 |  |
                                 |  |

Customer <-- AbTestVisitor <--  AbTestResults   --> Order



Value
-----
How do you add up the value of test X / option Y ?  Look at all the
results.  Eahc has a value.  Sum those up.


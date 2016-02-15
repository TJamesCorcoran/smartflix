Purpose
=======

Provide a UI bar across the top of the website in development mode
that helps developers.

Installation
============

1) miscellaneous
----------------

* We assume that you have a environment variable 'SESSION_TIMEOUT'
* We assume you have 'jquery' installed

2) models
---------

N/A  

3) views
--------

In your customer-facing layout  add this:

    <%= render :partial => 'shared/devel_bar' %>

4) CSS
------

something like this:

	div#devel_bar {
	  background-color: #ccc;
	  font-size: 16px;
	  min-height:32px;
	}

5) routes
---------

in

  config/routes.rb

put

  DevelBar.add_routes(binding, "admin")

BUGS
----

* 'show origins' functionality broke because 

      plugins/devel_bar/app/views/shared/_devel_bar_origins.rhtml
 
   depends on 

       Origin.get_all_from_session_id(session_id)

	which is broken


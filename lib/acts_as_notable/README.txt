
1) cd app/models
   ln -s ../../vendor/plugins/acts_as_notable/lib/note.rb

2) cd db/migrate
   ln -s  ../../vendor/plugins/acts_as_notable/db/migrate/20100826204356_add_notes.rb 
   rake db:migrate
  
3) edit your app/models/FOO.rb 

   require 'acts_as_notable'   # <<<< new line!

   class Foo
       acts_as_notable         # <<<< new line!

	   ...
   end


4) put code in your admin controllers to read and write notes

   controller
   ----------

   Two lines:

		  require 'acts_as_notable_controller'   # <----- line 1

		  class Base < ApplicationController
			acts_as_notable_controller           # <----- line 2
			...
		  end

    ALSO: it'd be really nice if in your admin::base controller you
    had something like this:

		before_filter :setup_employee
		def setup_employee
		  @employee = Person.find_by_person_id(session[:employee_number])  || Person.first
		end


    view
    ----

    (1) I've put standard code in the standard admin package (at least
    in SF), so the view "just works" ... "for free".

	(2) ...but if you're doing it by hand, for some reason, you want
	something like this:

	    <%
          # for acts_as_notable plugin
        %>
		<% if @customer.notes.empty? %>
			 <i>no notes yet</i>
		  <% else %>
			  most recent note first:
			  <% @customer.notes.reverse.each do |note| %>
				<div style="border: 1px solid black; margin:5px;">
				  <b><%= note.created_at.strftime("%Y-%m-%d %H:%M:%S") %> - <%= Person[note.employee_id].full_name if note.employee_id >0 %></b>
				  <br><br>
				  <%= note.note %>
				</div>
			<% end %>
		  <% end %>

		  New note:
		  <div style="border: 1px solid black; margin:5px;">
			<% form_tag( {:action => 'add_note'}, {:method => :post} ) do %>
			  <%= text_area_tag 'text', "", { :cols => 80, :row => 5} %>     
			  <%= hidden_field_tag 'id', @customer.id %>     
			  <%= submit_tag "Create" %>
			<% end %>
		  </div>

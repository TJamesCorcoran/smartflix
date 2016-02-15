Purpose
=======

Provide a very simple admin screen.

Installation
============

1) miscellaneous
----------------

	1.1) We assume that your layout supports

		  * flash[:message]
		  * flash[:error]

	1.2) All of your admin controllers presumably inherit from something
	like

		app/controllers/admin/base.rb

	in there put

		require 'acts_as_auto_admin_controller'   #  <---- line 1

		module Admin
		  class Base < ApplicationController
			...
			acts_as_auto_admin_controller          #  <---- line 2
			...
		  end
		end



2) models
---------

   Things you can add to your models to help them coexist:

        # allows admin screens to search by 'name'
		#
		def self.name_column_equiv() 
           "item_code_root" 
        end

        # ??
		#
		def self.advice_fields_required
			["title_id", "issue_number"]
		end
		
		# in the 'show' page
		# we can have links next to relationships that allow
		# admins to jump into a wizard to create certain relationships
		#
		def self.advice_relations_creatable_via_admin
			["covers"]
		end

		# in the 'show' page
		# we can have small X's next to relationships that allow
		# admins to destroy relationships
		#
		def self.advice_relations_deletable_via_admin
			["covers"]
		end


3) views
--------

	3.1) in your app/views/admin/shared

		ln -s ../../../../vendor/plugins/auto_admin/app/views/_edit.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_form.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_form_sub.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_index.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_index_core.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_new.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_notes.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_search.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_show.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_show_basicdata.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_show_relations.rhtml
		ln -s ../../../../vendor/plugins/auto_admin/app/views/_showdata.rhtml


	3.2) create file    >>>   index.rhtml

		<% content_for :sidebar do %>   # OPTIONAL
		   ...							# OPTIONAL
		   ...							# OPTIONAL
		<% end %>						# OPTIONAL

		<%= render (:partial => 'shared/index', :locals => { :items => @items,
															 :reverse => true #OPTIONAL
		 } )  %>


	3.3) create file    >>>  show.rhtml

		<% content_for :sidebar do %>   # OPTIONAL
		   ...							# OPTIONAL
		   ...							# OPTIONAL
		<% end %>						# OPTIONAL


		<h1>One <%= @item.class.to_s %></h1>
		<%= link_to "back to index", :action => :index %>


		<%= render (:partial => 'shared/show_basicdata', 
		            :locals => { :item => @item,
							     # following bit is option, if you
								 # want to render data differently
						 		 #
							     :partials => { :billing_address_id => "admin/addresses/compact_from_id",
                                 		        :shipping_address_id => "admin/addresses/compact_from_id"
												}
								}
                    )
           %>

		<%= render (:partial => 'shared/show_relations', :locals => { :item => @item, 
																	  :reject => [] # OPTIONAL
		  })  %>



4) controllers
--------------

	If you want to use auto_admin for class Foo, edit/create the file

		  app/controllers/admin/foo_controller.rb

	   with code

		  class Admin::FoosController < Admin::Base

			def get_class() Foos  end

		  end


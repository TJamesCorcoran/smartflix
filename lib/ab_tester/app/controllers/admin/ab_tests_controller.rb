require "will_paginate/array" # Necessary in AB test  admin pages, where I want to do complex selects on converged tests that aren't ammenable to SQL


class Admin::AbTestsController < Admin::Base

  def get_class() AbTest   end

  def active() 
    @class = get_class()
    @items = @class.active.paginate( :page => params[:page] || 1, :per_page => 50)
#    @items = @class.paginate( :page => params[:page] || 1, :per_page => 50)

    @override_page_title = "Active Tests"
  end

  def converged() 
    @class = get_class()
    @items = @class.list_converted_but_still_active.paginate( :page => params[:page] || 1, :per_page => 50)
    @override_page_title = "Converged and Active Tests"
  end

end


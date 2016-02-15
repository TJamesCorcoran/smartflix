module CustomerHelper

  # For problem reporting, button to click on when either canceling or
  # done; it closes the report box if using AJAX, or redirects to the
  # order page if not

  def report_problem_close(text)
    link_to(Button.new(text, :class => :w),
                   { :url => { :action => 'report_problem', :id => @line_item, :cancel => true }, :remote => true },
                   { :href => url_for(:action => 'order', :id => @line_item.order.id) })
  end

  # For problem reporting, button to click on when going back to the
  # first step; it does the right thing either with AJAX or without
  #
  def report_problem_back(text)
    # XXXFIX P3: This could be changed to allow the previous selection to be kept when going back
    link_to(Button.new(text, :class => :w),
                   { :url => { :action => 'report_problem', :id => @line_item }, :remote => true },
                   { :href => url_for(:action => 'report_problem', :id => @line_item) })
  end

end

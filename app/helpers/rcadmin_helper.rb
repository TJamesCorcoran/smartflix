module RcadminHelper

  # Given pages from a paginate call, create previous and next links;
  # the :invert option, if true, swaps the direction (useful for reverse
  # ordered lists)

  def links_to_previous_next(pages, options = {})
    options.assert_valid_keys(:invert)
    prev_page, next_page = pages.current.previous, pages.current.next
    prev_page, next_page = next_page, prev_page if options[:invert]
    output = prev_page ? link_to('Previous', :overwrite_params => { :page => prev_page, :results_only => false }) : 'Previous'
    output << ' '
    output << (next_page ? link_to('Next', :overwrite_params => { :page => next_page, :results_only => false }) : 'Next')
    return output
  end

end

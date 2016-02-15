require 'enumerator'

module StoreHelper

  def affiliate_link(object)
    return unless @customer && @customer.affiliate?

    link = case object.class.to_s
        when 'Video'   then link_to_product object, nil, "af#{@customer.id}"
        when 'UnivStub'   then link_to_product object, nil, "af#{@customer.id}"
        when 'Category'  then link_to_category object, nil, "af#{@customer.id}"
        when 'Author'    then link_to_author object, nil, "af#{@customer.id}"
      end

    
    noun = object.is_a?(UnivStub) ? "University" : object.class
    content_tag("div",
                content_tag("h4", "Affiliate link to this #{noun} &nbsp;(" + link_to('Help','/affiliate') + ")") +
                text_area_tag(:affiliate_link,
                              link,
                              {:rows => 4, :cols => 50, :onclick => onclick='this.focus(); this.select();'}
                ), :class => 'affiliate_link')
  end


  def customer_rented_or_review(product)
    return unless @customer
    return unless @customer.has_rented?(product)

    review = unless @customer.has_reviewed?(product)
      link_to "Review this", {:action => :review, :id => @product}
    end
    content_tag("p", "You have already rented this video.&nbsp;&nbsp;" + review.to_s, {:class => 'warning'})
  end

  # given a string that names a widget, figure out the names of the partials
  # that implement the widget, and then render them.
  #
  def frontpage_widgets(widgets=[], secondary_widgets=[])
    (widgets.sort_by { rand }.map { |w| render(:partial => w, :locals => { :customer => @customer }) } +
    secondary_widgets.sort_by { rand }.map { |w| render(:partial => w, :locals => { :customer => @customer }) } ).join.html_safe
  end

end

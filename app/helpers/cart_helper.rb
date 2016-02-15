module CartHelper

  # Create button used for deleting a product from the shopping cart
  def delete_from_cart_button_for(item)
    output = form_tag cart_delete_url(item.product.class.to_s, item.product.id)
    output << image_button(:delete, :submit => true)
    output << "</form>".html_safe
    return output.html_safe
  end

  # Create button used for making a cart item be saved for later or buy now
  def toggle_save_for_later_button_for(item)
    output = form_tag( { :action => 'move' })
    output << hidden_field_tag("id", item.product.id)
    if (item.saved_for_later?)
      output << image_button(:move_to_cart, { :bg => :b, :submit => true } )
    else
      output << image_button(:save_for_later, { :bg => :b, :submit => true } )
    end
    output << "</form>".html_safe
    return output.html_safe
  end

  # Given a cart item and its price, return a table row suitable for displaying that item
  def cart_line_for_item(item, price, options)
    # XXXFIX DISPLAY: Use CSS, maybe for table, certainly for font below
    output = "<tr>"
    if (options[:style] == :full)
      output << "<td>#{delete_from_cart_button_for(item)}</td>"
      output << "<td>#{toggle_save_for_later_button_for(item)}</td>"
    end
    output << "<td valign=\"top\">"
    if (item.product.product_set_member?)
      output << link_to_product(item.product.product_set.first)
      output << " (Disc ##{item.product.product_set_ordinal})"
      if (options[:style] == :full)
        output << "<br>"
        output << "<font size = -2>"
        output << item.product.name
        output << "</font>"
      end
    else
      output << link_to_product(item.product)
    end
    output << "</td>"
    output << "<td align=\"right\" valign=\"top\">#{number_to_currency(price) if price > 0 || item.product.is_a?(UnivStub)}"

    if item.discount?
      output << "<br><font size = -2>(after #{number_to_currency_if_positive(item.discount)} discount!)</font>"
    end

    output << "</td>"
    output << "</tr>"

    return output.html_safe
  end

  # Given a cart and a method to call on the cart to get the list of
  # items to display, return an appropriate cart display for them: sets
  # are listed together, and set discounts are included, and everything
  # is bundled in a table; options include setting the style to full or
  # summary by setting the :style option (default is :full) and setting
  # whether the total should be displayed (default is true)

  def cart_display_for(cart, method, options = { :style => :full, 
                                                 :display_total => true, 
                                                 :display_credit_style => :regular })

    options.assert_valid_keys(:style, :display_total, :display_credit_style)

    items = cart.send(method)

    output = '<table id="cart_display_for" border="0" width="100%" cellspacing="0" cellpadding="2">'

    CartGroup.groups_for_items(items, :discount => cart.global_discount).each do |group|

      if (options[:style] == :full && group.bundle_discount?)
        output << "<tr><td colspan=\"4\"><strong>Video bundle: #{group.name}</strong></td></tr>"
        output << "<tr><td colspan=\"#{options[:style] == :full ? 4 : 2}\">&nbsp;</td></tr>"
      end

      group.items_with_prices do |item, price|
        display_price = price - item.discount.to_f
        output << cart_line_for_item(item, display_price, options)
      end

      # Spacer row (4 or 2 columns wide depending on display style)
      output << "<tr><td colspan=\"#{options[:style] == :full ? 4 : 2}\">&nbsp;</td></tr>"

    end

    # Display the total, if requested
    if (options[:display_total])

      price_modification_total = 0.0
      if (@price_modifiers)
        @price_modifiers.each do |pm|
          output << '<tr>'
          output << '<td colspan="2"></td>' if (options[:style] == :full)
          output << "<td align=\"right\">#{pm.display_string}:&nbsp;&nbsp;</td>"
          output << "<td align=\"right\">#{number_to_currency(pm.amount)}</td>"
          output << '</tr>'
          price_modification_total += pm.amount
        end
      end

      # COMPLETED ABTEST: Should we show a free shipping line in the shopping cart?
      # RESULT: cart_free_shipping is not a win (surprising!), don't show it
      # output << '<tr>'
      # output << '<td colspan="2"></td>' if (options[:style] == :full)
      # output << '<td align="right">Free Shipping!&nbsp;&nbsp;</td>'
      # output << "<td align=\"right\">#{number_to_currency(0.00)}</td>"
      # output << '</tr>'

      total = cart.total + price_modification_total
      if (options[:display_credit_style] == :credit)
        output << '<tr>'
        output << '<td colspan="2"></td>' if (options[:style] == :full)
        output << '<td align="right">Account credit:&nbsp;&nbsp;</td>'
        output << "<td align=\"right\"><b>-#{number_to_currency(@usable_account_credit)}</b></td>"
        output << '</tr>'
        total = total - @usable_account_credit
      elsif (options[:display_credit_style] == :month) && cart.univ_stubs.any?
        output << '<tr>'
        output << '<td colspan="2"></td>' if (options[:style] == :full)
        output << '<td align="right">University credit:&nbsp;&nbsp;</td>'
        output << "<td align=\"right\"><b>-#{number_to_currency(cart.univ_stubs.first.price)}</b></td>"
        output << '</tr>'
        total = total - one_univ_month_credit_to_dollars(cart)
      end
      

        output << '<tr>'
        output << '<td colspan="2"></td>' if (options[:style] == :full)
        output << "<td class='comparison_right'><strong>List price:</strong></td>"
        output << "<td class='comparison_right'><span class='purchase_price_product'>#{cart.purchase_price.currency}</span></td>"
        output << '</tr>'

        output << '<tr>'
        output << '<td colspan="2"></td>' if (options[:style] == :full)
        output << "<td class='comparison_right'><strong>Rental price:</strong></td>"
        output << "<td class='comparison_right'><span class='rental_price_product'>#{total.currency}</span></td>"
        output << '</tr>'

        output << '<tr>'
        output << '<td colspan="2"></td>' if (options[:style] == :full)
        output << "<td class='comparison_right' ><strong>you save:</strong></td>"
        output << "<td class='comparison_right'><span class='savings_price_product'>#{(cart.savings_from_purchase).currency}</span></td>"
        output << "<td class='comparison_right'>(#{cart.percent_savings_from_purchase}%)</td>"

        output << '</tr>'

        output << '<tr>'
        output << '<td colspan="2"></td>' if (options[:style] == :full)
        output << "<td></td>"
        output << '</tr>'


        output << '<tr>'

    end

    output << '</table>'

    return output.html_safe

  end

  # Display the correct string counting the saved items portion of the cart
  def saved_items_count_string_for(count)
    "You have " + case count
                  when 0 then "no saved items"
                  when 1 then "one saved item"
                  else "#{count} saved items"
                  end
  end

end

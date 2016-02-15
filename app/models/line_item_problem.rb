class LineItemProblem < ActiveRecord::Base
  self.primary_key = "line_item_problem_id"
  attr_protected # <-- blank means total access


  belongs_to :line_item
  belongs_to :line_item_problem_type
  belongs_to :replacement_order, :class_name => 'Order', :foreign_key => 'replacement_order_id'

  # Make sure the the supplied barcode number is valid
  # XXXFIX P3: Consider setting max dynamically based on actual top copy number
  validates_inclusion_of(:wrong_copy_id,
                         :in => 2000..269999,
                         :if => lambda { |lip| !lip.wrong_copy_id.nil? },
                         :message => 'is not a valid barcode ID')

  # Require a barcode number
  def validate
    if self.line_item_problem_type.form_tag == 'wrong_dvd' && self.wrong_copy_id.nil?
      errors.add_to_base("Barcode number is required")
    end
  end

  # Return an array of all the valid problem types
  def LineItemProblem.valid_types
    LineItemProblemType.find(:all).collect { |pt| pt.form_tag }
  end

  # A list of the types that allow reshipment
  ReshipTypes = ['damaged_cracked', 'damaged_not_readable', 'damaged_skips', 'damaged_freezes',
                 'damaged_sound', 'damaged_other', 'wrong_dvd', 'late']

  # We don't have knowledge of copies in railscart, so we put this
  # functionality here because this is where it's used

  # Convert a copy ID to the ID on a sticker
  def LineItemProblem.copy_id_to_sticker(copy_id)
    copy_id = copy_id.to_i
    ten_thousands = copy_id / 10000
    prefix = (ten_thousands + 9).to_s(36).upcase if (ten_thousands > 0)
    return prefix.to_s + ("%04d" % (copy_id % 10000))
  end

  # Convert a sticker ID to a copy ID
  def LineItemProblem.sticker_to_copy_id(sticker)
    sticker = sticker.to_s
    case sticker
    when '' then nil
    when /^[a-z][0-9][0-9][0-9][0-9]$/i then ((sticker[0,1].to_i(36) - 9) * 10000) + sticker[1,sticker.length-1].to_i
    when /^[0-9]{0,4}$/ then sticker.to_i
    else 0
    end
  end

  # Given user supplied parameters, create a LineItemProblem and return
  # it (with any appropriate errors set)
  def LineItemProblem.for_report(line_item, problem_type_string, params, ip_address)

    # Should only be able to put in one replacement order per item
    return nil if (line_item.line_item_problem)

    # If the item is not even shipped yet, no deal
    return nil if (!line_item.shipped?)

    # If the item has already been returned, no deal
    return nil if (line_item.returned?)

    # Make sure the params match the problem report: wrong_copy_id only for wrong copy
    return nil if (params[:wrong_copy_id] && problem_type_string != 'wrong_dvd')

    # Reship only if a problem where reship is allowed
    return nil if (params[:reship] && !ReshipTypes.include?(problem_type_string))

    # Late only if line item is actually late
    return nil if (problem_type_string == 'late' && !line_item.late?)

    # Find the problem type specified, watching for SQL injection
    problem_type = LineItemProblemType.find(:first, :conditions => ['form_tag = ?', problem_type_string])
    if (!problem_type)
      return nil
    end

    # Create the problem
    problem = LineItemProblem.create(:line_item => line_item,
                                     :line_item_problem_type => problem_type,
                                     :details => params[:details],
                                     :wrong_copy_id => LineItemProblem.sticker_to_copy_id(params[:wrong_copy_id]))
    if (problem.errors.size > 0)
      return problem
    end

    # Create the replacement order if needed
    if (params[:reship] == 'yes')
      # XXXFIX P2: Consider for_replacement method in Order
      order = Order.new
      order.customer = line_item.order.customer
      order.ip_address = ip_address
      order.line_items << LineItem.for_product(line_item.product, 0.0)
      # XXXFIX P2: Consider for_replacement method in Payment, and others that set up payment method string (one place all strings!)
      payment = Payment.new(:order => order,
                            :customer => order.customer,
                            :payment_method => 'Free Replacement',
                            :amount => '0.0',
                            :complete => 1,
                            :successful => 1,
                            :status => 1)
      problem.replacement_order = order
      Order.transaction do
        order.save!
        payment.save!
        problem.save!
      end
    end

    return problem

  end

end

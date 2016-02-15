class Admin::AffiliateTransactionsController < Admin::Base
  def get_class() AffiliateTransaction end

  def index
    trans = AffiliateTransaction.find(:all)
    @affiliates = []
    trans.each { |tr| @affiliates << tr.affiliate_customer}
    @affiliates.uniq!
#    raise @affiliates.inspect

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @affiliate_transactions.to_xml }
    end
  end

  def show
    @affiliate_transactions = AffiliateTransaction.find(:all, :conditions =>"affiliate_customer_id = #{params[:id]}")

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @affiliate_transactions.to_xml }
    end
  end

  def create_payment
    trans = AffiliateTransaction.new(params[:affiliate_transaction])
    respond_to do |format|
      if trans.save
        addr = trans.affiliate_customer.billing_address
        first_payment = trans.affiliate_customer.affiliate_transactions.detect { |t| t.transaction_type == 'P' }.nil?
        flash[:notice] = "Payment noted in db. Please cut and mail a check for $#{ - trans.amount } and record in gnucash<br><br>" +
          "  #{addr.first_name} #{addr.last_name}<br>" +
          "  #{addr.address_1}<br>" +
          (( addr.address_2.size > 0) ?  "#{addr.address_2}<br>" : "") +
          "  #{addr.city}, #{addr.state_name} #{addr.postcode}<br>" +
          (first_payment ? "" : "<br>FIRST PAYMENT, NEW PAYROLL SETUP REQUIRED")


        format.html { redirect_to  :action =>:index }
      else
        flash[:error] = 'Payment failed'
        format.html { redirect_to   :action =>:index }
      end
    end
  end

end

class Admin::CobrandsController < Admin::Base
  def get_class() Cobrand end

  def index
    @cobrands = Cobrand.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @cobrands.to_xml }
    end
  end

  def show
    @cobrand = Cobrand.find(params[:id])
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @cobrands.to_xml }
    end
  end

  def create_payment
    @cobrand_payment = CobrandPayment.new(params[:cobrand_payments])

    respond_to do |format|
      if @cobrand_payment.save
        flash[:notice] = "Payment noted in db. Please cut and mail a check for $#{ @cobrand_payment.payment } and record in gnucash."
        format.html { redirect_to :controller=>:cobrands, :action =>:index }
      else
        flash[:error] = 'CobrandPayment failed'
        format.html { redirect_to  :controller=>:cobrands, :action =>:index }
      end
    end
  end

end

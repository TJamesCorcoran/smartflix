class Admin::CcChargeStatusesController < Admin::Base
  def get_class() CcChargeStatus end


  def index
    @cc_charge_statuses = CcChargeStatus.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cc_charge_statuses }
    end
  end

  def show
    @cc_charge_status = CcChargeStatus.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cc_charge_status }
    end
  end

  def update
    @cc_charge_status = CcChargeStatus.find(params[:id])

    respond_to do |format|
      if @cc_charge_status.update_attributes(params[:cc_charge_status])
        flash[:notice] = 'CcChargeStatus was successfully updated.'
        format.html { redirect_to(@cc_charge_status) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cc_charge_status.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @cc_charge_status = CcChargeStatus.find(params[:id])
    @cc_charge_status.destroy

    respond_to do |format|
      format.html { redirect_to(cc_charge_statuses_url) }
      format.xml  { head :ok }
    end
  end
end

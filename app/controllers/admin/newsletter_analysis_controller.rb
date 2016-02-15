class Admin::NewsletterAnalysisController < Admin::Base

  def index
    params[:showdata] = true if   params[:showdata].nil?
    limit = params[:limit] || 20
    @newsletters = Newsletter.find(:all, :order => "#{Newsletter.primary_key} DESC", :limit => limit)
  end  

end

class Admin::EbayAuctionsController < Admin::Base
  def get_class() EbayAuction end

  def index
    @items = []
    if (params[:search_str].nil?) 
      @items = EbayAuction.find(:all, :order => "ebay_auctions_id desc", :limit =>30)
    else
      @items = EbayAuction.find_all_by_email_addr(params[:search_str]) +
        EbayAuction.find_all_by_ebay_item_id(params[:search_str]) +
        EbayAuction.find_all_by_ebay_user_id(params[:search_str]) +
        EbayAuction.find_all_by_coupon_code(params[:search_str]) +
        EbayAuction.find_all_by_auction_date(params[:search_str]) +
        EbayAuction.find_all_by_coupon_issue_date(params[:search_str])
    end
  end
  
  def show
    @ebay_auction = EbayAuction.find(params[:id])
  end
end

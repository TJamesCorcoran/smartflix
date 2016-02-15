class Admin::VideoAssetsController < Admin::Base
  def get_class() VideoAsset end
  def get_class() VideoAsset   end

  def depreciation
    @depreciation = Hash.new(0)
    VideoAsset.all.each do |va|
      quant = va.dollars / 36
      36.times do |x|
        month = va.acquired >> x
        @depreciation[month] = @depreciation[month] + quant
      end
    end
  end

  def cumulative
    sum = 0
    @cum = VideoAsset.all.sort_by(&:acquired).map { |va| before = sum ; sum += va.dollars ; { :before => before, :after => sum, :va => va }  }
  end


end

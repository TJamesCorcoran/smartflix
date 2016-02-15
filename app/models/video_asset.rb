class VideoAsset < ActiveRecord::Base
  self.primary_key ="video_asset_id"

  attr_protected # <-- blank means total access

  validates_uniqueness_of :acquired

end

class FavoriteProjectLink < ActiveRecord::Base
  self.primary_key = "favorite_project_link_id"
  attr_protected # <-- blank means total access

  belongs_to :project
  belongs_to :customer
end

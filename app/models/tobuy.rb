class Tobuy < ActiveRecord::Base
  self.primary_key ="tobuy_id"

  attr_protected # <-- blank means total access

  belongs_to :product

  def self.updated_at
    Tobuy.connection.select_one("select max(updated_at) from tobuys").values.first
  end
end

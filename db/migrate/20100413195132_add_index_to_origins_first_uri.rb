class AddIndexToOriginsFirstUri < ActiveRecord::Migration
  def self.up
     add_index    :origins, :first_uri
     add_index    :origins, :first_coupon
     add_index    :origins, :referer
     add_index    :origins, :updated_at
  end
  
  def self.down
    remove_index    :origins, :first_uri
    remove_index    :origins, :first_coupon
    remove_index    :origins, :referer
    remove_index    :origins, :updated_at
  end
end

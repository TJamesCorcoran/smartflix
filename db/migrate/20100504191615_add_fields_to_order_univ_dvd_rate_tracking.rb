class AddFieldsToOrderUnivDvdRateTracking < ActiveRecord::Migration
  def self.up
    add_column     :order_univ_dvd_rate_updates, :order_id, :int, :null => false
    add_column     :order_univ_dvd_rate_updates, :note, :string
  end

  def self.down
    remove_column     :order_univ_dvd_rate_updates, :order_id
    remove_column     :order_univ_dvd_rate_updates, :note
  end
end

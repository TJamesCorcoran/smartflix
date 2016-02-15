class AddStatusToPayment < ActiveRecord::Migration
  def self.up

    add_column :payments, :status, :integer, :null => true

  end

  def self.down
    remove_column :payments, :status
  end
end

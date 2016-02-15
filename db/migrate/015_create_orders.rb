class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table(:orders, :primary_key => 'order_id') do |t|
      t.column :customer_id, :integer, :null => false
      t.column :ip_address, :string, :null => false
      t.column :created_at, :datetime, :null => false

      # XXXFIX P2: Store an address with the order, seperate from the
      # customer's shipping address (because that can change), by adding
      # an address_id here and changing the address change code to be
      # smart (if an address has orders, create a new one when doing edits)

    end
    add_index :orders, :customer_id
  end

  def self.down
    drop_table :orders
  end
end

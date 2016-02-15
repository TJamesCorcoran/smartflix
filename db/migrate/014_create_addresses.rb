class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table(:addresses, :primary_key => 'address_id') do |t|
      t.column :first_name, :string, :null => false
      t.column :last_name, :string, :null => false
      t.column :address_1, :string, :null => false
      t.column :address_2, :string, :null => false
      t.column :city, :string, :null => false
      t.column :state_id, :integer, :null => false
      t.column :postcode, :string, :null => false
      t.column :country_id, :integer, :null => false
      t.column :type, :string, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :addresses
  end
end

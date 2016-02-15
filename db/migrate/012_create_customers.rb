class CreateCustomers < ActiveRecord::Migration
  def self.up
    create_table(:customers, :primary_key => 'customer_id') do |t|
      t.column :email, :string, :null => false
      t.column :hashed_password, :string, :null => false
      t.column :first_name, :string, :null => false
      t.column :last_name, :string, :null => false
      t.column :shipping_address_id, :integer, :null => false
      t.column :billing_address_id, :integer, :null => false
      t.column :affiliate, :boolean, :null => false, :default => false
      t.column :encrypted_ssn, :text, :null => true, :default => nil
      t.column :updated_at, :datetime, :null => false
    end
    add_index :customers, :email
  end

  def self.down
    drop_table :customers
  end
end

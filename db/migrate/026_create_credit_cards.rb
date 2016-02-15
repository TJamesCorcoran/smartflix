class CreateCreditCards < ActiveRecord::Migration
  def self.up
    create_table(:credit_cards, :primary_key => 'credit_card_id') do |t|
      t.column :customer_id, :integer, :null => false
      t.column :encrypted_number, :text, :null => false
      t.column :month, :integer, :null => false
      t.column :year, :integer, :null => false
      t.column :first_name, :string, :null => false
      t.column :last_name, :string, :null => false
      t.column :type, :string, :null => false
    end
  end

  def self.down
    drop_table :credit_cards
  end
end

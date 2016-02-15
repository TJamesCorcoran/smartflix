class CreateSuggestions < ActiveRecord::Migration
  def self.up
    create_table(:suggestions, :primary_key => 'suggestion_id') do |t|
      t.column :name, :string, :null => false
      t.column :email, :string, :null => false
      t.column :title, :string, :null => false
      t.column :where_to_buy, :string, :null => false
      t.column :ip_address, :string, :null => false
      t.column :customer_id, :integer, :null => true
    end
  end

  def self.down
    drop_table :suggestions
  end
end

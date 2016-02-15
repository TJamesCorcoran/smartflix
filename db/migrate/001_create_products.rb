class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table(:products, :primary_key => 'product_id') do |t|
      t.column :type,           :string,  :null => false
      t.column :name,           :string,  :null => false
      t.column :description,    :text,    :null => false
      t.column :price,          :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :date_added,     :date,    :null => false
      t.column :author_id,      :integer, :null => false
      t.column :minutes,        :integer, :null => false
      t.column :days_backorder, :integer, :null => false, :default => 0
      t.column :display,        :boolean, :null => false
      t.column :handout,        :string,  :null => true
      t.column :num_copies,     :integer, :null => false, :default => 0
    end
  end

  def self.down
    drop_table :products
  end
end

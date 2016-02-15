class CreateLineItemStatusCodes < ActiveRecord::Migration
  def self.up
    create_table(:line_item_status_codes, :primary_key => 'line_item_status_code_id') do |t|
      t.column :name, :string, :null => false
    end
    LineItemStatusCode.create(:name => 'pending')
    LineItemStatusCode.create(:name => 'shipped')
    LineItemStatusCode.create(:name => 'returned')
    LineItemStatusCode.create(:name => 'cancelled')
  end

  def self.down
    drop_table :line_item_status_codes
  end
end

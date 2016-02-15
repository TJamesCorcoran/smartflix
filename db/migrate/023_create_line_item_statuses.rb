class CreateLineItemStatuses < ActiveRecord::Migration
  def self.up
    create_table(:line_item_statuses, :primary_key => 'line_item_status_id') do |t|
      t.column :line_item_id, :integer, :null => false
      t.column :line_item_status_code_id, :integer, :null => false
      t.column :shipment_date, :date, :null => true
      t.column :early_arrival_date, :date, :null => true
      t.column :late_arrival_date, :date, :null => true
      t.column :place_in_line, :integer, :null => true
      t.column :days_delay, :integer, :null => true, :default => 0
    end
  end

  def self.down
    drop_table :line_item_statuses
  end
end

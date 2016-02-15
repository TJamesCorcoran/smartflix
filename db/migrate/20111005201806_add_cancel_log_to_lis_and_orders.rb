class AddCancelLogToLisAndOrders < ActiveRecord::Migration
  def self.up
    create_table :cancellation_logs do |t|
      t.boolean  :new_liveness, :null => false, :default=> true

      t.string  :reference_type, :null => false
      t.integer :reference_id, :null => false

      t.timestamps
    end
    
    
  end

  def self.down
    drop_table :cancellation_logs
  end
end

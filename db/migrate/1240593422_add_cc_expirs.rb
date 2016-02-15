class AddCcExpirs < ActiveRecord::Migration
  def self.up
    create_table 'cc_expirations' do |t|
      t.column 'cc_charge_status_id', :integer
      t.column 'payment_id', :integer
      t.column 'month', :integer
      t.column 'year', :integer
    end

  end

  def self.down
    drop_table 'cc_expirations'
  end
end

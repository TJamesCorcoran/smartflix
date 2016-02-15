class AddCreditCardStatuses < ActiveRecord::Migration
  def self.up
    create_table (:cc_charge_statuses) do |t|
      t.column :credit_card_id, :integer, :null => false
      t.column :status, :bool, :null => false
      t.column :amount, :decimal, :precision =>8, :scale =>2, :null => false
      t.column :message, :string, :null => false

      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

  end

  def self.down
    drop_table :cc_charge_statuses
  end
end

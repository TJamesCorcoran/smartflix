class CreateGiftCertificates < ActiveRecord::Migration
  def self.up
    create_table(:gift_certificates, :primary_key => 'gift_certificate_id') do |t|
      t.column :code, :string, :null => false
      t.column :amount, :decimal, :precision => 9, :scale => 2, :default => '0.00', :null => false
      t.column :used, :boolean, :null => false, :default => false
      t.column :created_at, :datetime, :null => false
    end
    add_index :gift_certificates, :code
  end

  def self.down
    drop_table :gift_certificates
  end
end

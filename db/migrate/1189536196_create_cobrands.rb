class CreateCobrands < ActiveRecord::Migration
  def self.up
    create_table(:cobrands, :primary_key => 'cobrand_id') do |t|
      t.column :name, :string, :null => false
    end
    add_index :cobrands, :name
    Cobrand.create(:name => 'woodturningonline')
    Cobrand.create(:name => 'makezine')
    Cobrand.create(:name => 'craftzine')
  end

  def self.down
    drop_table :cobrands
  end
end

class AddNotes < ActiveRecord::Migration
  def self.up
    create_table "notes" do |t|
      t.column "notable_id",   :integer,:null => false
      t.column "notable_type", :string, :null => false
      t.column "note",         :string, :null => false
      t.column "employee_id",   :integer,:null => false
      t.timestamps
    end
  end

  def self.down
    drop_table "notes"
  end
end

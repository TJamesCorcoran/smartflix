class AddDeathTypes < ActiveRecord::Migration
  def self.up
    create_table "death_types", :primary_key => "death_type_id", :force => true do |t|
      t.string "name"
    end
    
  end

  def self.down
    drop_table "death_types"
  end
end

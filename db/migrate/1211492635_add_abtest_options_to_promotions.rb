class AddAbtestOptionsToPromotions < ActiveRecord::Migration
  def self.up

    add_column :promotions, :ab_test_name, :string, :null => true
    add_column :promotions, :ab_test_alternative, :string, :null => true

  end

  def self.down

    add_column :promotions, :ab_test_name
    add_column :promotions, :ab_test_alternative

  end
end

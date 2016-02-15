class TweakCcTypeField < ActiveRecord::Migration
  def up
    rename_column :credit_cards, :type, :brand
  end

  def down
    rename_column :credit_cards, :brand, :type
  end
end

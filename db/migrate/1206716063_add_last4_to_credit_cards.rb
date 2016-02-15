class AddLast4ToCreditCards < ActiveRecord::Migration
  def self.up
    add_column :credit_cards, :last_four, :string
  end

  def self.down
    remove_column :credit_cards, :last_four
  end
end

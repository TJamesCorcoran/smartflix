class AbTestListAuthorInProdListings < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:author_names_on_listings, 1, 0.0, [:false, :true])
  end

  def self.down
  end
end

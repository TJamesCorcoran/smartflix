class CreateInitialNewsletterCategories < ActiveRecord::Migration
  def self.up
    NewsletterCategory.create(:name => "all customers",
                              :code => "Customer.find(:all)")
  end

  def self.down
    NewsletterCategory.destroy_all
  end
end

class AddNewsletterCatCurrentUnivCustomers < ActiveRecord::Migration
  def self.up
    NewsletterCategory.create(:code => "Order.university_orders.map(&:customer).uniq",
                              :name => "University customers")
  end

  def self.down
    NewsletterCategory.find_by_name("University customers").destroy
  end
end

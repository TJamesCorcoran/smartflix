class AddAbtestForUnivEmails < ActiveRecord::Migration
  def self.up
    AbTester.create_test(:univreco_mail_subject,  
                         0,               # flight
                         0.0,             # type (float)
                         [:brand_and_price, 
                          :one_month_free, 
                          :come_back, 
                          :newsletter_coupon, 
                          :newsletter_expiration,
                          :univ_name])
 
    AbTester.create_test(:univreco_mail_body,  
                         0,               # flight
                         0.0,             # type (float)
                         [:chatty, 
                          :chatty_with_prices,
                          :huckster, 
                          :focus_on_univ])
  end

  def self.down
    AbTester.destroy_test(:univreco_mail_subject)
    AbTester.destroy_test(:univreco_mail_body)
  end
end

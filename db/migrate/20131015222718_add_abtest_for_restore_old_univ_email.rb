class AddAbtestForRestoreOldUnivEmail < ActiveRecord::Migration
  def up
    AbTester.create_test(:univ_comeback_mail_subject,  
                         0,               # flight
                         0.0,             # type (float)
                         [:brand_and_price, 
                          :newsletter_expiration,
                          :newsletter_coupon])
 
    AbTester.create_test(:univ_comeback_mail_body,  
                         0,               # flight
                         0.0,             # type (float)
                         [:chatty])
  end

  def down
    AbTester.destroy_test(:univ_comeback_mail_subject)
    AbTester.destroy_test(:univ_comeback_mail_body)
  end
end

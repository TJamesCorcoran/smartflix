class NewsletterMailer < ActionMailer::Base
  
  def newsletter(to, customer, newsletter)

    # MAKE SURE THAT THIS ADDRESS ACTUALLY EXISTS.
    # MAIL WILL SILENTLY NOT BE SENT OTHERWISE
    headers["return-path"] = (Rails.application.class)::EMAIL_TO_BOUNCES

    @customer = customer
    @newsletter = newsletter
    
    
    mail(
         to:         Rails.env.production? ? customer.email : (Rails.application.class)::EMAIL_TO_DEVELOPER,
         from:       (Rails.application.class)::EMAIL_FROM,
         subject:    "[#{(Rails.application.class)::SITE_NAME}] #{newsletter.headline}"
         ).deliver
    
    
  end

end

# can maybe go inside above class definition
NewsletterMailer.view_paths = ["#{Rails.root}/lib/newsletter/app/views" ]

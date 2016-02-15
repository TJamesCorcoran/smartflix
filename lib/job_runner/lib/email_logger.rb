class EmailLogger < Logger
  
  def initialize(email_to, subject)
    
    @mail_buffer = StringIO.new()

    super(@mail_buffer)
    
    at_exit {
      ActionMailer::Base.mail(:from    => (Rails.application.class)::EMAIL_FROM_AUTO,
                              :to		 => email_to,
                              :subject => subject,
                              :body	 => @mail_buffer.string).deliver
    }
  end
  
#  def info(str)
#    @mail_buffer.write(str)
#  end
  
end



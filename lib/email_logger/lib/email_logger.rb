# Wrapper for the logger class that sends the log information via email
# on application exit (useful for small program run by cron, not useful
# for a long running program!)

# class EmailLogger < Logger

#   def initialize(email_to, subject)
#     mail_buffer = StringIO.new()
#     super(mail_buffer)
#     at_exit { SfMailer.simple_message(email_to, SmartFlix::Application::EMAIL_FROM_AUTO, subject, mail_buffer.string) }
#   end

# end

# If we ever use this out of rails context, where we want our own format
#self.formatter = MyLogFormatter.new 
#class MyLogFormatter < Logger::Formatter 
#  MyLogFormat = "%s: %s\n" 
#  def call(severity, time, progname, msg )
#    # If ever want to format time, use format_datetime(time)
#    MyLogFormat % [severity[0,1], msg2str(msg)] 
#  end
#end

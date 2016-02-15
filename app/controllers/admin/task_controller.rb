class Admin::TaskController < Admin::Base

  # XXXFIX P2: This does not currently work: database goes away for
  # ActiveRecord (???) and ssh tunnels don't get killed

  def pull
    render_text 'Currently disabled...'
    return
    if request.post?
      @result = TVR.capture_log { TVR::Pull.order_info }
    end
  rescue => e
    @result = "ERROR: pull failed (#{e})"
  ensure
    SfMailer.simple_message(SmartFlix::Application::EMAIL_TO_DEFAULT, SmartFlix::Application::EMAIL_FROM_AUTO, "RAILSCART: Someone clicked 'pull'", @result) if @result
  end

end

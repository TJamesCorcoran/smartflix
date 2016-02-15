class RobotTest

  def self.is_robot?(request, session)
    
    # ua = AgentOrange::UserAgent.new(request.env["HTTP_USER_AGENT"])
    # device = ua.device
    # puts "AO-1 #{device.type} / #{device.name} / #{device.version}"
    # puts "AO-2 #{device.is_mobile?} / #{device.is_computer?} / #{device.is_bot?}"
    # platform = ua.device.platform
    # puts "AO-3 #{platform.type} / #{platform.name} / #{platform.version}"
    # os = ua.device.operating_systtem
    # puts "AO-3 #{os.type} / #{os.name} / #{os.version}"
    # en = ua.device.engine
    # puts "AO-3 #{en.type} / #{en.name} / #{en.version}"
    # br = ua.device.browser
    
    return session[:is_robot] unless session[:is_robot].nil?

     if request.nil?
       session[:is_robot] = true
     elsif request.env["HTTP_USER_AGENT"].nil?
       session[:is_robot] = true
     else
       session[:is_robot] = AgentOrange::UserAgent.new(request.env["HTTP_USER_AGENT"]).device.andand.is_bot?
     end

  end
end

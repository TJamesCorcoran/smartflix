class DevelBarRoutes
  def self.add_routes(context, namespace = "admin")
    
    context.eval( %Q(
        namespace '#{namespace}' do

          match "devel_bar/flush_cookie"    => 'devel_bar#flush_cookie'    , :as  => :devel_bar_flush_cookie
          match "devel_bar/set_abtest"      => 'devel_bar#set_ab_test'     , :as  => :devel_bar_set_ab_test
          match "devel_bar/set_session_var" => 'devel_bar#set_session_var' , :as  => :devel_bar_set_session_var
          match "devel_bar/del_session_var/:kk" => 'devel_bar#del_session_var' , :as  => :devel_bar_del_session_var

        end # namespace
    )) # eval
  end # def
end # class

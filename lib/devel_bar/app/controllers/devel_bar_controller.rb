include Abt


class Admin::DevelBarController < ApplicationController
  
  # this is SUPER important; if these functions existed in production
  # ANYONE could seize the machine!!!
  #
  if Rails.env.development?
    
    def flush_cookie
      reset_session
      begin
        redirect_to :back
      rescue ActionController::RedirectBackError
        redirect_to "/"
      end
    end
    
    def set_ab_test
      ab_test!(params[:test_name], params[:option_name])
      redirect_to :back
    end
    
    def set_session_var
      kk = params[:kk]
      vv = params[:vv]
      # if user passes in something like
      #   "eval(1 + 1)"
      # or 
      #   "eval(GraphicNovel[12])"
      # do the eval.
      #
      # SUPER MASSIVE SECURITY HOLE ---> note the 
      #    Rails.env.development? 
      # above!
      #
      # belt-and-suspenders:
      raise "illegal" unless Rails.env.development?
      if vv.match(/^eval\(\"(.*)\"\)$/)
        vv = eval($1)
      end
      session[kk] = vv
      redirect_to :back    
    end

    def del_session_var
      kk = params[:kk]
      session.delete(kk)
      redirect_to :back    
    end
    
  end
end

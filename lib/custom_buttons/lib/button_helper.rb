module ActionView
  module Helpers
    module ButtonHelper

      def button(content,url,*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        Button.new(content,options.merge( :url => url)).to_s
      end
      
    end
  end
end

ActionView::Base.instance_eval { include ActionView::Helpers::ButtonHelper }

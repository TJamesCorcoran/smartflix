class NewsletterEditor
  module Helper
    module Mailer
      # for each smartflix url in the newsletter:
      #   if the href url does not yet have arguments, 
      #        add the newsletter campaign id to the end of the url
      #   if it already has arguments, just skip it.  Too dicey to try to hack.
      def campaign_ids(html, newsletter)
        # XYZFIX P1: Get app host name from app?
        urls = [ WEB_SERVER ]
        urls = "(" + urls.join("|") + ")"
        html.gsub(/href="(http:\/\/#{urls}.*?)"/) do |x| 
          urlmatch = $1
          if (x =~ /\?/)
            "href=\"#{urlmatch}\""
          else
            newurl = "href=\"#{urlmatch}?ct=nl#{newsletter.id}\""
            newurl
          end
        end
      end
    end
  end
end

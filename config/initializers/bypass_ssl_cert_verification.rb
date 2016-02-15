# on 15 March 2012 we're using 
#   50.28.52.222
# as our mail server and the cert doesn't work

require 'openssl'

module OpenSSL
  module SSL
    class SSLSocket
      def post_connection_check(hostname)
        true
      end
    end
  end
end


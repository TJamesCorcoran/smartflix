module Encryptor

  # Utility function to encrypt strings, like credit card numbers and
  # SSNs, using a one way RSA key
  #
  # Private keys should not be backed up to the liquidweb server.
  #
  # Private keys should not be checked into revision control.
  #
  # Generating RSA keys:
  #
  #   openssl genrsa -aes256 -out privkey.pem 2048
  #
  # Isolating the public key
  #
  #   openssl rsa -in privkey.pem -out pubkey.pem -pubout -outform PEM

  def Encryptor.one_way_encrypt_string(string)

    # Load the public key from the file, if not already loaded
    if (!defined? @@public_key)
      keyfile = "#{Rails.root}/config/#{SmartFlix::Application::CC_ENCRYPT_KEY_FILENAME}"
      @@public_key = OpenSSL::PKey::RSA.new(File.read(keyfile))
    end

    # Encrypt and base64 encode the result
    return Base64.encode64(@@public_key.public_encrypt(string)).gsub(/\s/, '')

  end

end

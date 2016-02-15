module Decryptor

  # Utility function to decrypt strings, like credit card numbers and
  # SSNs, using a one way RSA key

  def Decryptor.decrypt_string(string)

    if (!defined? @@private_key)
      keyfile = "#{Rails.root}/config/#{SmartFlix::Application::CC_DECRYPT_KEY_FILENAME}"
      password = "XXX"
      @@private_key = OpenSSL::PKey::RSA.new(File.read(keyfile), password)
    end

    # Base64 decode and decrypt the result
    ciphertext = Base64.decode64(string)
    cleartext = @@private_key.private_decrypt(ciphertext)
    return cleartext

  end

end

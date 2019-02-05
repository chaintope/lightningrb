# frozen_string_literal: true

module Lightning
  module Wire
    class Signature
      def encode
        self.class.der2wire(value).htb
      end

      def self.decode_from(payload)
        sig = payload.read(64)
        new(value: wire2der(sig))
      end

      # @return DER format hex string
      def self.wire2der(signature)
        # TODO: raise Lightning::Crypto::DER::SignatureLengthError.new unless signature.size == 64
        r = signature[0...32]
        s = signature[32...64]
        sig = Lightning::Crypto::DER.encode(r, s)
        sig.bth
      end

      # @return hex format string
      def self.der2wire(der)
        # TODO: raise Lightning::Crypto::DER::InvalidDERError.new unless Lightning::Crypto::DER.valid?(der)
        Lightning::Crypto::DER.decode(der.htb)
      end
    end
  end
end

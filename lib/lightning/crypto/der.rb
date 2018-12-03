# frozen_string_literal: true

module Lightning
  module Crypto
    module DER
      # r [String] binary string
      # s [String] binary string
      # return [String] DER binary string
      def self.encode(r, s)
        signature = ECDSA::Signature.new(r.bth.to_i(16), s.bth.to_i(16))
        ECDSA::Format::SignatureDerString.encode(signature)
      end

      # return [String] signature hex string
      def self.decode(sig_as_der)
        sig = ECDSA::Format::SignatureDerString.decode(sig_as_der)
        sig.r.to_s(16).rjust(64, '0') + sig.s.to_s(16).rjust(64, '0')
      end
    end
  end
end

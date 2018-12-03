# frozen_string_literal: true

require 'lightning/wire/types.pb'

module Lightning
  module Wire
    autoload :LightningMessages, 'lightning/wire/lightning_messages'
    autoload :LightningMessageTypes, 'lightning/wire/lightning_message_types'
    autoload :HandshakeMessages, 'lightning/wire/handshake_messages'

    class PascalString < ::Protobuf::Message
      def self.of(value)
        value = [value].pack("H*")
        new(length: value.length, value: value)
      end

      def decode_from(stream)
        self.length = self.class.get_field('length').decode_from(stream)
        bytes = stream.read(length)
        self.value = self.class.get_field('value').decode(bytes)
        self
      end
    end

    class Signature < ::Protobuf::Message
      def self.from_der(sig_as_der)
        sig = ECDSA::Format::SignatureDerString.decode(sig_as_der)
        new(r: sig.r.to_s(16).rjust(64, '0'), s: sig.s.to_s(16).rjust(64, '0'))
      end
    end
  end
end

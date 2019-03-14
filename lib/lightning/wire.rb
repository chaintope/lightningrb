# frozen_string_literal: true

require 'lightning/wire/types.pb'

module Lightning
  module Wire
    autoload :LightningMessages, 'lightning/wire/lightning_messages'
    autoload :HandshakeMessages, 'lightning/wire/handshake_messages'
    autoload :Serialization, 'lightning/wire/serialization'
    autoload :Signature, 'lightning/wire/signature'
  end
end

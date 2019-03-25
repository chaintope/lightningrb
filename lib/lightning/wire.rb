# frozen_string_literal: true

require 'lightning/wire/types.pb'
require 'lightning/wire/signature'

module Lightning
  module Wire
    autoload :LightningMessages, 'lightning/wire/lightning_messages'
    autoload :HandshakeMessages, 'lightning/wire/handshake_messages'
    autoload :Serialization, 'lightning/wire/serialization'
  end
end

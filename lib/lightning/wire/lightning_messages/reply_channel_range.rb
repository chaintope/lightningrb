# frozen_string_literal: true

require 'lightning/wire/lightning_messages/reply_channel_range.pb'

module Lightning
  module Wire
    module LightningMessages
      class ReplyChannelRange < Lightning::Wire::LightningMessages::Generated::ReplyChannelRange
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 264

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

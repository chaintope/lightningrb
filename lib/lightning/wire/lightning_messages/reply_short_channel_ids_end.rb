# frozen_string_literal: true

require 'lightning/wire/lightning_messages/reply_short_channel_ids_end.pb'

module Lightning
  module Wire
    module LightningMessages
      class ReplyShortChannelIdsEnd < Lightning::Wire::LightningMessages::Generated::ReplyShortChannelIdsEnd
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 262

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

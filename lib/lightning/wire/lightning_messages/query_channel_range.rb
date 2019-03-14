# frozen_string_literal: true

require 'lightning/wire/lightning_messages/query_channel_range.pb'

module Lightning
  module Wire
    module LightningMessages
      class QueryChannelRange < Lightning::Wire::LightningMessages::Generated::QueryChannelRange
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 263

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

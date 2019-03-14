# frozen_string_literal: true

require 'lightning/wire/lightning_messages/gossip_timestamp_filter.pb'

module Lightning
  module Wire
    module LightningMessages
      class GossipTimestampFilter < Lightning::Wire::LightningMessages::Generated::GossipTimestampFilter
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 265

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def match?(gossip_message)
          first_timestamp <= gossip_message.timestamp && gossip_message.timestamp < (first_timestamp + timestamp_range)
        end
      end
    end
  end
end

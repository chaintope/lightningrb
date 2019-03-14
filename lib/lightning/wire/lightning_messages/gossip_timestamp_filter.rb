# frozen_string_literal: true

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
      end
    end
  end
end

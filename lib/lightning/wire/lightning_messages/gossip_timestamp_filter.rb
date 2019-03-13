# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class GossipTimeStampFilter < Lightning::Wire::LightningMessages::Generated::GossipTimeStampFilter
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

# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class AnnouncementSignatures < Lightning::Wire::LightningMessages::Generated::AnnouncementSignatures
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 259

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class UpdateAddHtlc < Lightning::Wire::LightningMessages::Generated::UpdateAddHtlc
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        include Lightning::Wire::LightningMessages::UpdateMessage
        TYPE = 128

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

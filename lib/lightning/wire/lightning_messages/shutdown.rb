# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class Shutdown < Lightning::Wire::LightningMessages::Generated::Shutdown
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        TYPE = 38

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

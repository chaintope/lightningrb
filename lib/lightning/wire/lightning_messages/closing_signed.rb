# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class ClosingSigned < Lightning::Wire::LightningMessages::Generated::ClosingSigned
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        TYPE = 39

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

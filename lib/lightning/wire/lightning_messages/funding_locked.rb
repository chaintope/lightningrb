# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class FundingLocked < Lightning::Wire::LightningMessages::Generated::FundingLocked
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        TYPE = 36

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

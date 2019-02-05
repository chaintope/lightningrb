# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class UpdateFailMalformedHtlc < Lightning::Wire::LightningMessages::Generated::UpdateFailMalformedHtlc
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 135

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

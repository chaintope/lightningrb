# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class UpdateFulfillHtlc < Lightning::Wire::LightningMessages::Generated::UpdateFulfillHtlc
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 130

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

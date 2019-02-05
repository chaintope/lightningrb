# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class UpdateAddHtlc < Lightning::Wire::LightningMessages::Generated::UpdateAddHtlc
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 128

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class UpdateFee < Lightning::Wire::LightningMessages::Generated::UpdateFee
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 134

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

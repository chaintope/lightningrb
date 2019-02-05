# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class UpdateFailHtlc < Lightning::Wire::LightningMessages::Generated::UpdateFailHtlc
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 131

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class Error < Lightning::Wire::LightningMessages::Generated::Error
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 17

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

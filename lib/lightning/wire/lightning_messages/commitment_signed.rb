# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class CommitmentSigned < Lightning::Wire::LightningMessages::Generated::CommitmentSigned
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        TYPE = 132

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

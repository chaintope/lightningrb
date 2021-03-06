# frozen_string_literal: true

require 'lightning/wire/lightning_messages/commitment_signed.pb'

module Lightning
  module Wire
    module LightningMessages
      class CommitmentSigned < Lightning::Wire::LightningMessages::Generated::CommitmentSigned
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        include Lightning::Wire::LightningMessages::UpdateMessage
        TYPE = 132

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

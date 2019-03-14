# frozen_string_literal: true

require 'lightning/wire/lightning_messages/update_fee.pb'

module Lightning
  module Wire
    module LightningMessages
      class UpdateFee < Lightning::Wire::LightningMessages::Generated::UpdateFee
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        include Lightning::Wire::LightningMessages::UpdateMessage
        TYPE = 134

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

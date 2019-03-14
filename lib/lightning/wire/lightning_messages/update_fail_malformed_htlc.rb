# frozen_string_literal: true

require 'lightning/wire/lightning_messages/update_fail_malformed_htlc.pb'

module Lightning
  module Wire
    module LightningMessages
      class UpdateFailMalformedHtlc < Lightning::Wire::LightningMessages::Generated::UpdateFailMalformedHtlc
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        include Lightning::Wire::LightningMessages::UpdateMessage
        TYPE = 135

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

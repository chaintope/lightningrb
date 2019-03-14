# frozen_string_literal: true

require 'lightning/wire/lightning_messages/funding_signed.pb'

module Lightning
  module Wire
    module LightningMessages
      class FundingSigned < Lightning::Wire::LightningMessages::Generated::FundingSigned
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasChannelId
        TYPE = 35

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end
      end
    end
  end
end

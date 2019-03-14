# frozen_string_literal: true

require 'lightning/wire/lightning_messages/funding_created.pb'

module Lightning
  module Wire
    module LightningMessages
      class FundingCreated < Lightning::Wire::LightningMessages::Generated::FundingCreated
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasTemporaryChannelId
        TYPE = 34

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def validate!(temporary_channel_id)
          unless self[:temporary_channel_id] == temporary_channel_id
            raise Lightning::Exceptions::TemporaryChannelIdNotMatch.new(self[:temporary_channel_id])
          end
        end
      end
    end
  end
end

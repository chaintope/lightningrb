# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class FundingCreated < Lightning::Wire::LightningMessages::Generated::FundingCreated
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
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

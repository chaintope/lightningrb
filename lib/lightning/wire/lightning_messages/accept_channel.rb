# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      class AcceptChannel < Lightning::Wire::LightningMessages::Generated::AcceptChannel
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::HasTemporaryChannelId
        TYPE = 33

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def validate!(open)
          unless self[:temporary_channel_id] == open[:temporary_channel_id]
            raise Lightning::Exceptions::TemporaryChannelIdNotMatch.new(self[:temporary_channel_id])
          end
          if self[:channel_reserve_satoshis] < open[:dust_limit_satoshis]
            raise Lightning::Exceptions::InsufficientChannelReserve.new(self[:channel_reserve_satoshis])
          end
          if self[:dust_limit_satoshis] > open[:channel_reserve_satoshis]
            raise Lightning::Exceptions::InsufficientChannelReserve.new(open[:channel_reserve_satoshis])
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module AcceptChannel
        def self.load(payload)
          _, rest = payload.unpack('na*')
          unpack(rest)[0]
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::ACCEPT_CHANNEL
        end

        def self.builder
          @builder ||= Lightning::Utils::Serializer.new.hex(32).uint64.x(4).uint32.uint16.x(2).public_key.x(6)
        end

        def self.unpack(payload)
          args = builder.to_a(payload)
          [new(*(args[0])), args[1]]
        end

        def pack
          [AcceptChannel.to_type].pack('n') + AcceptChannel.builder.to_binary(*to_a)
        end

        def to_payload
          pack
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

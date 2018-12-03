# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module UpdateAddHtlc
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64q>2H64NH27132'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::UPDATE_ADD_HTLC
        end

        def to_payload
          payload = +''
          payload << [UpdateAddHtlc.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:id], self[:amount_msat]].pack('q>2')
          payload << self[:payment_hash].htb
          payload << [self[:cltv_expiry]].pack('N')
          payload << self[:onion_routing_packet].htb
          payload
        end

        def self.builder
          @builder ||= Lightning::Utils::Serializer.new.hex(32).uint64.x(2).hex(32).uint32.hex(13566)
        end

        def self.unpack(payload)
          args = builder.to_a(payload)
          [new(*(args[0])), args[1]]
        end

        def pack
          [UpdateAddHtlc.to_type].pack('n') + UpdateAddHtlc.builder.to_binary(*to_a)
        end
      end
    end
  end
end

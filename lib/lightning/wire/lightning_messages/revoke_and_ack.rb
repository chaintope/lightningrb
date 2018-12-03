# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module RevokeAndAck
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64H64H66'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::REVOKE_AND_ACK
        end

        def to_payload
          payload = +''
          payload << [RevokeAndAck.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << self[:per_commitment_secret].htb
          payload << self[:next_per_commitment_point].htb
          payload
        end
      end
    end
  end
end

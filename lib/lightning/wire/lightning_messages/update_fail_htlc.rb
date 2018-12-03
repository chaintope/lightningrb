# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module UpdateFailHtlc
        def self.load(payload)
          _, rest = payload.unpack('na*')
          channel_id, id, len, rest = rest.unpack('H64q>na*')
          reason, = rest.unpack("H#{len * 2}")
          new(channel_id, id, len, reason)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::UPDATE_FAIL_HTLC
        end

        def to_payload
          payload = +''
          payload << [UpdateFailHtlc.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:id], self[:len]].pack('q>n')
          payload << self[:reason].htb
          payload
        end
      end
    end
  end
end

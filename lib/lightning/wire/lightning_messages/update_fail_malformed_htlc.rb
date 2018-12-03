# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module UpdateFailMalformedHtlc
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64q>H64n'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::UPDATE_FAIL_MALFORMED_HTLC
        end

        def to_payload
          payload = +''
          payload << [UpdateFailMalformedHtlc.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:id]].pack('q>')
          payload << self[:sha256_of_onion].htb
          payload << [self[:failure_code]].pack('n')
          payload
        end
      end
    end
  end
end

# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module UpdateFulfillHtlc
        def self.load(payload)
          _, rest = payload.unpack('na*')
          new(*rest.unpack('H64q>H64'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::UPDATE_FULFILL_HTLC
        end

        def to_payload
          payload = +''
          payload << [UpdateFulfillHtlc.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:id]].pack('q>')
          payload << self[:payment_preimage].htb
          payload
        end
      end
    end
  end
end

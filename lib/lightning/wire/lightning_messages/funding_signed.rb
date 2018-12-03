# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module FundingSigned
        def self.load(payload)
          _, rest = payload.unpack('na*')
          channel_id, signature = rest.unpack('H64a64')
          signature = LightningMessages.wire2der(signature)
          new(channel_id, signature)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::FUNDING_SIGNED
        end

        def to_payload
          payload = +''
          payload << [FundingSigned.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << LightningMessages.der2wire(self[:signature].htb)
          payload
        end
      end
    end
  end
end

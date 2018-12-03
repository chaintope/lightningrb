# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module ClosingSigned
        def self.load(payload)
          _, channel_id, fee_satoshis, signature = payload.unpack('nH64q>a64')
          signature = LightningMessages.wire2der(signature)
          new(channel_id, fee_satoshis, signature)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::CLOSING_SIGNED
        end

        def to_payload
          payload = +''
          payload << [ClosingSigned.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:fee_satoshis]].pack('q>')
          payload << LightningMessages.der2wire(self[:signature].htb)
          payload
        end
      end
    end
  end
end

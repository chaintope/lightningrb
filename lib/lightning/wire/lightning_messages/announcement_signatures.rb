# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module AnnouncementSignatures
        def self.load(payload)
          _, channel_id, short_channel_id, node_signature, bitcoin_signature, = payload.unpack('nH64q>a64a64a*')
          node_signature = LightningMessages.wire2der(node_signature)
          bitcoin_signature = LightningMessages.wire2der(bitcoin_signature)
          new(channel_id, short_channel_id, node_signature, bitcoin_signature)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::ANNOUNCEMENT_SIGNATURES
        end

        def to_payload
          payload = +''
          payload << [AnnouncementSignatures.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << [self[:short_channel_id]].pack('q>')
          payload << LightningMessages.der2wire(self[:node_signature].htb)
          payload << LightningMessages.der2wire(self[:bitcoin_signature].htb)
          payload
        end
      end
    end
  end
end

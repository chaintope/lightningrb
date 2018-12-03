# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module CommitmentSigned
        def self.load(payload)
          _, channel_id, signature, num_htlcs, rest = payload.unpack('nH64a64na*')
          signature = LightningMessages.wire2der(signature)
          htlc_signature = rest.unpack('a64' * num_htlcs)
          htlc_signature = htlc_signature.map { |s| LightningMessages.wire2der(s) }
          new(channel_id, signature, num_htlcs, htlc_signature)
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::COMMITMENT_SIGNED
        end

        def to_payload
          payload = +''
          payload << [CommitmentSigned.to_type].pack('n')
          payload << self[:channel_id].htb
          payload << LightningMessages.der2wire(self[:signature].htb)
          payload << [self[:num_htlcs]].pack('n')
          payload << self[:htlc_signature].map { |s| LightningMessages.der2wire(s.htb) }.join('')
          payload
        end
      end
    end
  end
end

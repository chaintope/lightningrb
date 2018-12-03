# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module ChannelAnnouncement
        def self.load(payload)
          _, signatures, len, rest = payload.unpack('na256na*')
          signatures = signatures.unpack('a64a64a64a64').map { |sig| LightningMessages.wire2der(sig) }
          new(*(signatures + [len] + rest.unpack("a#{len}H64q>H66H66H66H66")))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::CHANNEL_ANNOUNCEMENT
        end

        def to_payload
          payload = +''
          payload << [ChannelAnnouncement.to_type].pack('n')
          payload << [
            self[:node_signature_1],
            self[:node_signature_2],
            self[:bitcoin_signature_1],
            self[:bitcoin_signature_2],
          ].map { |der| LightningMessages.der2wire(der.htb) }.join('')
          payload << [self[:len]].pack('n')
          payload << self[:features]
          payload << self[:chain_hash].htb
          payload << [self[:short_channel_id]].pack('q>')
          payload << self[:node_id_1].htb
          payload << self[:node_id_2].htb
          payload << self[:bitcoin_key_1].htb
          payload << self[:bitcoin_key_2].htb
          payload
        end

        def valid_signature?
          Bitcoin::Key.new(pubkey: self[:node_id_1]).verify(self[:node_signature_1].htb, witness) &&
          Bitcoin::Key.new(pubkey: self[:node_id_2]).verify(self[:node_signature_2].htb, witness) &&
          Bitcoin::Key.new(pubkey: self[:bitcoin_key_1]).verify(self[:bitcoin_signature_1].htb, witness) &&
          Bitcoin::Key.new(pubkey: self[:bitcoin_key_2]).verify(self[:bitcoin_signature_2].htb, witness)
        end

        def witness_data
          payload = +''
          payload << [self[:len]].pack('n')
          payload << self[:features]
          payload << self[:chain_hash].htb
          payload << [self[:short_channel_id]].pack('q>')
          payload << self[:node_id_1].htb
          payload << self[:node_id_2].htb
          payload << self[:bitcoin_key_1].htb
          payload << self[:bitcoin_key_2].htb
          payload
        end

        def witness
          Bitcoin.double_sha256(witness_data)
        end
      end
    end
  end
end

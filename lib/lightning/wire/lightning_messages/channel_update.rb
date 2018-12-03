# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module ChannelUpdate
        def self.load(payload)
          _, signature, rest = payload.unpack('na64a*')
          signature = LightningMessages.wire2der(signature)
          new(signature, *rest.unpack('H64q>NCCnq>N2'))
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::CHANNEL_UPDATE
        end

        def to_payload
          payload = +''
          payload << [ChannelUpdate.to_type].pack('n')
          payload << LightningMessages.der2wire(self[:signature].htb)
          payload << self[:chain_hash].htb
          payload << [
            self[:short_channel_id],
            self[:timestamp],
            self[:message_flags],
            self[:channel_flags],
            self[:cltv_expiry_delta],
            self[:htlc_minimum_msat],
            self[:fee_base_msat],
            self[:fee_proportional_millionths],
          ].pack('q>NCCnq>N2')
          payload
        end

        def copy(attributes)
          ChannelUpdate[
            attributes[:signature] || self[:signature],
            attributes[:chain_hash] || self[:chain_hash],
            attributes[:short_channel_id] || self[:short_channel_id],
            attributes[:timestamp] || self[:timestamp],
            attributes[:message_flags] || self[:message_flags],
            attributes[:channel_flags] || self[:channel_flags],
            attributes[:cltv_expiry_delta] || self[:cltv_expiry_delta],
            attributes[:htlc_minimum_msat] || self[:htlc_minimum_msat],
            attributes[:fee_base_msat] || self[:fee_base_msat],
            attributes[:fee_proportional_millionths] || self[:fee_proportional_millionths]
          ]
        end

        def valid_signature?(node_id)
          Bitcoin::Key.new(pubkey: node_id).verify(self[:signature].htb, witness)
        end

        def witness_data
          payload = +''
          payload << self[:chain_hash].htb
          payload << [
            self[:short_channel_id],
            self[:timestamp],
            self[:message_flags],
            self[:channel_flags],
            self[:cltv_expiry_delta],
            self[:htlc_minimum_msat],
            self[:fee_base_msat],
            self[:fee_proportional_millionths],
          ].pack('q>NCCnq>N2')
          payload
        end

        def witness
          Bitcoin.double_sha256(witness_data)
        end

        def self.witness(chain_hash, short_channel_id, timestamp, message_flags, channel_flags, cltv_expiry_delta, htlc_minimum_msat, fee_base_msat, fee_proportional_millionths)
          new(
            '',
            chain_hash,
            short_channel_id,
            timestamp,
            message_flags,
            channel_flags,
            cltv_expiry_delta,
            htlc_minimum_msat,
            fee_base_msat,
            fee_proportional_millionths
          ).witness
        end
      end
    end
  end
end

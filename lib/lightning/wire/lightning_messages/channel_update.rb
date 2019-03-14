# frozen_string_literal: true

require 'lightning/wire/lightning_messages/channel_update.pb'

module Lightning
  module Wire
    module LightningMessages
      class ChannelUpdate < Lightning::Wire::LightningMessages::Generated::ChannelUpdate
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 258

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def copy(attributes)
          ChannelUpdate.new(
            signature: attributes[:signature] || self.signature,
            chain_hash: attributes[:chain_hash] || self.chain_hash,
            short_channel_id: attributes[:short_channel_id] || self.short_channel_id,
            timestamp: attributes[:timestamp] || self.timestamp,
            message_flags: attributes[:message_flags] || self.message_flags,
            channel_flags: attributes[:channel_flags] || self.channel_flags,
            cltv_expiry_delta: attributes[:cltv_expiry_delta] || self.cltv_expiry_delta,
            htlc_minimum_msat: attributes[:htlc_minimum_msat] || self.htlc_minimum_msat,
            fee_base_msat: attributes[:fee_base_msat] || self.fee_base_msat,
            fee_proportional_millionths: attributes[:fee_proportional_millionths] || self.fee_proportional_millionths,
            htlc_maximum_msat: attributes[:htlc_maximum_msat] || self.htlc_maximum_msat,
          )
        end

        def valid_signature?(node_id)
          Bitcoin::Key.new(pubkey: node_id).verify(signature.value.htb, witness)
        end

        def witness
          self.class.witness(chain_hash, short_channel_id, timestamp, message_flags, channel_flags, cltv_expiry_delta, htlc_minimum_msat, fee_base_msat, fee_proportional_millionths, htlc_maximum_msat)
        end

        def self.witness(chain_hash, short_channel_id, timestamp, message_flags, channel_flags, cltv_expiry_delta, htlc_minimum_msat, fee_base_msat, fee_proportional_millionths, htlc_maximum_msat)
          witness = ChannelUpdateWitness.new(
            chain_hash: chain_hash,
            short_channel_id: short_channel_id,
            timestamp: timestamp,
            message_flags: message_flags,
            channel_flags: channel_flags,
            cltv_expiry_delta: cltv_expiry_delta,
            htlc_minimum_msat: htlc_minimum_msat,
            fee_base_msat: fee_base_msat,
            fee_proportional_millionths: fee_proportional_millionths,
            htlc_maximum_msat: htlc_maximum_msat
          )
          stream = StringIO.new
          Protobuf::Encoder.encode(witness, stream)
          Bitcoin.double_sha256(stream.string)
        end
      end

      class ChannelUpdateWitness < Lightning::Wire::LightningMessages::Generated::ChannelUpdateWitness
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
      end
    end
  end
end

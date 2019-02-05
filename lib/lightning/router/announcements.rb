# frozen_string_literal: true

module Lightning
  module Router
    module Announcements
      class << self
        include Lightning::Wire::LightningMessages
        def make_announcement_signatures(node_params, commitments, short_channel_id)
          features = ''
          local_node_signature, local_bitcoin_signature = channel_announcement_signature(
            node_params.chain_hash,
            short_channel_id,
            node_params.private_key,
            commitments[:remote_param][:node_id],
            commitments[:local_param][:funding_priv_key].priv_key,
            commitments[:remote_param][:funding_pubkey],
            features
          )
          AnnouncementSignatures.new(
            channel_id: commitments[:channel_id],
            short_channel_id: short_channel_id,
            node_signature: local_node_signature,
            bitcoin_signature: local_bitcoin_signature
          )
        end

        def make_channel_announcement(
          chain_hash,
          short_channel_id,
          local_node_id,
          remote_node_id,
          local_funding_key,
          remote_funding_key,
          local_node_signature,
          remote_node_signature,
          local_bitcoin_signature,
          remote_bitcoin_signature)

          node_id_1, node_id_2, bitcoin_key_1, bitcoin_key_2, node_signature_1, node_signature_2, bitcoin_signature_1, bitcoin_signature_2 =
            if node1?(local_node_id, remote_node_id)
              [local_node_id, remote_node_id, local_funding_key, remote_funding_key, local_node_signature, remote_node_signature, local_bitcoin_signature, remote_bitcoin_signature]
            else
              [remote_node_id, local_node_id, remote_funding_key, local_funding_key, remote_node_signature, local_node_signature, remote_bitcoin_signature, local_bitcoin_signature]
            end

          announcement = ChannelAnnouncement.new(
            node_signature_1: node_signature_1,
            node_signature_2: node_signature_2,
            bitcoin_signature_1: bitcoin_signature_1,
            bitcoin_signature_2: bitcoin_signature_2,
            features: '',
            chain_hash: chain_hash,
            short_channel_id: short_channel_id,
            node_id_1: node_id_1,
            node_id_2: node_id_2,
            bitcoin_key_1: bitcoin_key_1,
            bitcoin_key_2: bitcoin_key_2
          )
          announcement
        end

        def channel_announcement_signature(
          chain_hash,
          short_channel_id,
          local_node_secret,
          remote_node_id,
          local_funding_private_key,
          remote_funding_key,
          features
          )
          node_key = Bitcoin::Key.new(priv_key: local_node_secret)
          funding_key = Bitcoin::Key.new(priv_key: local_funding_private_key)
          local_node_id = node_key.pubkey
          local_funding_key = funding_key.pubkey

          node_id_1, node_id_2, bitcoin_key_1, bitcoin_key_2 =
            if node1?(local_node_id, remote_node_id)
              [local_node_id, remote_node_id, local_funding_key, remote_funding_key]
            else
              [remote_node_id, local_node_id, remote_funding_key, local_funding_key]
            end
          witness = ChannelAnnouncement.witness(features, chain_hash, short_channel_id, node_id_1, node_id_2, bitcoin_key_1, bitcoin_key_2)
          [
            Lightning::Wire::Signature.new(value: node_key.sign(witness).bth),
            Lightning::Wire::Signature.new(value: funding_key.sign(witness).bth)
          ]
        end

        def make_node_announcement(
          node_secret,
          node_rgb_color,
          node_alias,
          addresses,
          timestamp
          )
          node_id = Bitcoin::Key.new(priv_key: node_secret).pubkey
          signature = node_announcement_signature(
            '', timestamp, node_secret, node_rgb_color, node_alias, addresses
          )
          NodeAnnouncement.new(
            signature: signature,
            features: '',
            timestamp: timestamp,
            node_id: node_id,
            node_rgb_color: node_rgb_color,
            node_alias: node_alias,
            addresses: addresses
          )
        end

        def node_announcement_signature(features, timestamp, node_secret, node_rgb_color, node_alias, addresses)
          node_key = Bitcoin::Key.new(priv_key: node_secret)
          node_id = node_key.pubkey
          witness = NodeAnnouncement.witness(features, timestamp, node_id, node_rgb_color, node_alias, addresses)
          Lightning::Wire::Signature.new(value: node_key.sign(witness).bth)
        end

        def make_channel_update(
          chain_hash,
          node_secret,
          remote_node_id,
          short_channel_id,
          cltv_expiry_delta,
          htlc_minimum_msat,
          fee_base_msat,
          fee_proportional_millionths,
          timestamp: Time.now.to_i,
          htlc_maximum_msat: 0
        )

          local_node_id = Bitcoin::Key.new(priv_key: node_secret).pubkey
          message_flags = "00"
          channel_flags =
            if node1?(local_node_id, remote_node_id)
              "01"
            else
              "00"
            end
          signature = channel_update_signature(node_secret,
            chain_hash,
            short_channel_id,
            timestamp,
            message_flags,
            channel_flags,
            cltv_expiry_delta,
            htlc_minimum_msat,
            fee_base_msat,
            fee_proportional_millionths,
            htlc_maximum_msat
          )

          ChannelUpdate.new(
            signature: signature,
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
        end

        def channel_update_signature(node_secret,
          chain_hash,
          short_channel_id,
          timestamp,
          message_flags,
          channel_flags,
          cltv_expiry_delta,
          htlc_minimum_msat,
          fee_base_msat,
          fee_proportional_millionths,
          htlc_maximum_msat
        )
          node_key = Bitcoin::Key.new(priv_key: node_secret)
          witness = ChannelUpdate.witness(chain_hash,
            short_channel_id,
            timestamp,
            message_flags,
            channel_flags,
            cltv_expiry_delta,
            htlc_minimum_msat,
            fee_base_msat,
            fee_proportional_millionths,
            htlc_maximum_msat
          )
          Lightning::Wire::Signature.new(value: node_key.sign(witness).bth)
        end

        def to_channel_desc(channel)
          node_id_1, node_id_2 =
            if node1?(channel[:node_id_1], channel[:node_id_2])
              [channel[:node_id_1], channel[:node_id_2]]
            else
              [channel[:node_id_2], channel[:node_id_1]]
            end
          Lightning::Router::Messages::ChannelDesc[channel[:short_channel_id], node_id_1, node_id_2]
        end

        private

        def node1?(local_node_id, remote_node_id)
          Lightning::Utils::LexicographicalOrdering.less_than?(local_node_id, remote_node_id)
        end
      end
    end
  end
end

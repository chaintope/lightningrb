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
          AnnouncementSignatures[
            commitments[:channel_id], short_channel_id, local_node_signature, local_bitcoin_signature
          ]
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

          node_id_1, node_id_2, bitcoin_key_1, bitcion_key_2, node_signature_1, node_signature_2, bitcoin_signature_1, bitcoin_signature_2 =
            if node1?(local_node_id, remote_node_id)
              [local_node_id, remote_node_id, local_funding_key, remote_funding_key, local_node_signature, remote_node_signature, local_bitcoin_signature, remote_bitcoin_signature]
            else
              [remote_node_id, local_node_id, remote_funding_key, local_funding_key, remote_node_signature, local_node_signature, remote_bitcoin_signature, local_bitcoin_signature]
            end
          ChannelAnnouncement[
            node_signature_1,
            node_signature_2,
            bitcoin_signature_1,
            bitcoin_signature_2,
            0,
            '',
            chain_hash,
            short_channel_id,
            node_id_1,
            node_id_2,
            bitcoin_key_1,
            bitcion_key_2
          ]
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
          [node_key.sign(witness).bth, funding_key.sign(witness).bth]
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
          NodeAnnouncement[
            signature,
            0,
            '',
            timestamp,
            node_id,
            node_rgb_color,
            node_alias,
            addresses.size,
            addresses
          ]
        end

        def node_announcement_signature(features, timestamp, node_secret, node_rgb_color, node_alias, addresses)
          node_key = Bitcoin::Key.new(priv_key: node_secret)
          node_id = node_key.pubkey
          witness = NodeAnnouncement.witness(features, timestamp, node_id, node_rgb_color, node_alias, addresses)
          node_key.sign(witness).bth
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
          timestamp: Time.now.to_i
        )

          local_node_id = Bitcoin::Key.new(priv_key: node_secret).pubkey
          message_flags = 0
          channel_flags =
            if node1?(local_node_id, remote_node_id)
              "00000001".to_i(2)
            else
              "00000000".to_i(2)
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
            fee_proportional_millionths
          )

          ChannelUpdate[
            signature,
            chain_hash,
            short_channel_id,
            timestamp,
            message_flags,
            channel_flags,
            cltv_expiry_delta,
            htlc_minimum_msat,
            fee_base_msat,
            fee_proportional_millionths
          ]
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
          fee_proportional_millionths
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
            fee_proportional_millionths
          )
          node_key.sign(witness).bth
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

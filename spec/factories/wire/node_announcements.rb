# frozen_string_literal: true

FactoryBot.define do
  factory(:node_announcement, class: 'Lightning::Wire::LightningMessages::NodeAnnouncement') do
    features { ''.htb }
    timestamp { 1 }
    node_rgb_color { (100 << 16) + (200 << 8) + 44 }
    node_alias { "node-alias\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" }
    addresses { '01c0a8012aa410' }

    initialize_with do
      node_key = build(:key, :remote_funding_privkey)
      node_id = node_key.pubkey
      witness = Lightning::Wire::LightningMessages::NodeAnnouncement.witness(features, timestamp, node_id, node_rgb_color, node_alias, addresses)
      signature = Lightning::Wire::Signature.new(value: node_key.sign(witness).bth)
      new(
        signature: signature,
        features: features,
        timestamp: timestamp,
        node_id: node_id,
        node_rgb_color: node_rgb_color,
        node_alias: node_alias,
        addresses: addresses
      )
    end
  end
end

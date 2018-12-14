# frozen_string_literal: true

FactoryBot.define do
  factory(:node_announcement, class: 'FactoryBotWrapper') do
    signature do
      '3045022100a1df390c304ca230b19200912f0121d6f9c0d3cdc09ce76627544d' \
      'f4e7a6b06602205195f043fe86ac91228c7980b23471db18c69375727d0a9c97' \
      'd06daf7202ae5b'
    end
    flen { 0 }
    features { ''.htb }
    timestamp { 1 }
    node_id { build(:key, :remote_funding_pubkey).pubkey }
    node_rgb_color { [100, 200, 44] }
    node_alias { 'node-alias' }
    addrlen { 1 }
    addresses { ['192.168.1.42:42000'] }

    initialize_with do
      new(Lightning::Wire::LightningMessages::NodeAnnouncement[
        signature,
        flen,
        features,
        timestamp,
        node_id,
        node_rgb_color,
        node_alias,
        addrlen,
        addresses
      ])
    end
  end
end

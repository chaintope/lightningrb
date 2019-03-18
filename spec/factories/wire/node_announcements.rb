# frozen_string_literal: true

FactoryBot.define do
  factory(:node_announcement, class: 'Lightning::Wire::LightningMessages::NodeAnnouncement') do
    signature { build(:signature) }
    features { ''.htb }
    timestamp { 1 }
    node_id { build(:key, :remote_funding_pubkey).pubkey }
    node_rgb_color { (100 << 16) + (200 << 8) + 44 }
    node_alias { "node-alias\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" }
    addresses { '01c0a8012aa410' }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_announcement, class: 'Lightning::Wire::LightningMessages::ChannelAnnouncement') do
    node_signature_1 { build(:signature) }
    node_signature_2 { build(:signature) }
    bitcoin_signature_1 { build(:signature) }
    bitcoin_signature_2 { build(:signature) }
    features { ''.htb }
    chain_hash { '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f' }
    short_channel_id { 0 }
    node_id_1 { build(:key, :remote_funding_pubkey).pubkey }
    node_id_2 { build(:key, :local_funding_pubkey).pubkey }
    bitcoin_key_1 { build(:key, :local_pubkey).pubkey }
    bitcoin_key_2 { build(:key, :local_pubkey).pubkey }
  end
end

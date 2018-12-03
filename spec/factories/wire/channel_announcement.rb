# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_announcement, class: 'FactoryBotWrapper') do
    node_signature_1 { build(:signature) }
    node_signature_2 { build(:signature) }
    bitcoin_signature_1 { build(:signature) }
    bitcoin_signature_2 { build(:signature) }
    len 0
    features { ''.htb }
    chain_hash '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f'
    short_channel_id 0
    node_id_1 { build(:key, :remote_funding_pubkey).pubkey }
    node_id_2 { build(:key, :local_funding_pubkey).pubkey }
    bitcoin_key_1 ''
    bitcoin_key_2 ''

    initialize_with do
      new(Lightning::Wire::LightningMessages::ChannelAnnouncement[
        node_signature_1,
        node_signature_2,
        bitcoin_signature_1,
        bitcoin_signature_2,
        len,
        features,
        chain_hash,
        short_channel_id,
        node_id_1,
        node_id_2,
        bitcoin_key_1,
        bitcoin_key_2,
      ])
    end
  end
end

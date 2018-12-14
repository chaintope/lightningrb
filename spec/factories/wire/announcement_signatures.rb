# frozen_string_literal: true

FactoryBot.define do
  factory(:announcement_signatures, class: 'FactoryBotWrapper') do
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    short_channel_id { 1 }
    node_signature { build(:signature) }
    bitcoin_signature { build(:signature) }

    initialize_with do
      new(Lightning::Wire::LightningMessages::AnnouncementSignatures[
        channel_id, short_channel_id, node_signature, bitcoin_signature
      ])
    end
  end
end

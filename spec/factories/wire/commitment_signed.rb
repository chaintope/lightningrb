# frozen_string_literal: true

FactoryBot.define do
  factory(:commitment_signed, class: 'FactoryBotWrapper') do
    channel_id '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff'
    signature do
      '304402203af8e2d8a6087d47f65cd4a6fc5282c9beedd18dbaf1813b5de26ec4' \
      'e677debb02203e2ba9b2d28896baef050460f916d7c20b39e1462868f4c15670' \
      'd4c8c2b6f1d1'
    end
    num_htlcs 0
    htlc_signature []
    initialize_with do
      new(Lightning::Wire::LightningMessages::CommitmentSigned[
        channel_id,
        signature,
        num_htlcs,
        htlc_signature
      ])
    end

    trait :has_htlcs do
      num_htlcs 1
      htlc_signature ['99' * 32]
    end

    trait :invalid do
      signature do
        '304402203af8e2d8a6087d47f65cd4a6fc5282c9beedd18dbaf1813b5de26ec4' \
        'e677debb02203e2ba9b2d28896baef050460f916d7c20b39e1462868f4c15670' \
        'd4c8c2b6f1d2'
      end
    end
  end
end

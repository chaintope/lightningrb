# frozen_string_literal: true

FactoryBot.define do
  factory(:closing_signed, class: 'FactoryBotWrapper') do
    channel_id '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff'
    fee_satoshis 1_000
    signature '304402203af8e2d8a6087d47f65cd4a6fc5282c9beedd18dbaf1813b5de26ec4e677debb02203e2ba9b2d28896baef050460f916d7c20b39e1462868f4c15670d4c8c2b6f1d1'
    initialize_with do
      new(Lightning::Wire::LightningMessages::ClosingSigned[
        channel_id,
        fee_satoshis,
        signature
      ])
    end
  end
end

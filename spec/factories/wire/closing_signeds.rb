# frozen_string_literal: true

FactoryBot.define do
  factory(:closing_signed, class: 'Lightning::Wire::LightningMessages::ClosingSigned') do
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    fee_satoshis { 1_000 }
    signature { build(:signature) }
  end
end

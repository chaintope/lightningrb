# frozen_string_literal: true

FactoryBot.define do
  factory(:revoke_and_ack, class: 'Lightning::Wire::LightningMessages::RevokeAndAck') do
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    per_commitment_secret { '1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100' }
    next_per_commitment_point { '031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f' }
  end
end

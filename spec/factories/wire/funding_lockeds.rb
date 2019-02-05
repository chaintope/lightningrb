# frozen_string_literal: true

FactoryBot.define do
  factory(:funding_locked, class: 'Lightning::Wire::LightningMessages::FundingLocked') do
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    next_per_commitment_point { '031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f' }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory(:shutdown, class: 'Lightning::Wire::LightningMessages::Shutdown') do
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    scriptpubkey { '0014ccf1af2f2aabee14bb40fa3851ab2301de843110' }
  end
end

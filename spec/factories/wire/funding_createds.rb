# frozen_string_literal: true

FactoryBot.define do
  factory(:funding_created, class: 'Lightning::Wire::LightningMessages::FundingCreated') do
    temporary_channel_id { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    funding_txid { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6be' }
    funding_output_index { 0 }
    signature { build(:signature) }
  end
end

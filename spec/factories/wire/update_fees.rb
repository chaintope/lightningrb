# frozen_string_literal: true

FactoryBot.define do
  factory(:update_fee, class: 'Lightning::Wire::LightningMessages::UpdateFee') do
    channel_id { "00" * 32 }
    feerate_per_kw { 46_080 }
  end
end

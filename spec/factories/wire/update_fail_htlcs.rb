# frozen_string_literal: true

FactoryBot.define do
  factory(:update_fail_htlc, class: 'Lightning::Wire::LightningMessages::UpdateFailHtlc') do
    channel_id { "00" * 32 }
    id { 0 }
    reason { '' }
  end
end

# frozen_string_literal: true

FactoryBot.define do
  r = Bitcoin.sha256("\x42" * 32).bth
  factory(:update_fulfill_htlc, class: 'Lightning::Wire::LightningMessages::UpdateFulfillHtlc') do
    channel_id { "00" * 32 }
    id { 0 }
    payment_preimage { r }
  end
end

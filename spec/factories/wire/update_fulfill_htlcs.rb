# frozen_string_literal: true

FactoryBot.define do
  r = Bitcoin.sha256("\x42" * 32).bth
  factory(:update_fulfill_htlc, class: 'FactoryBotWrapper') do
    channel_id { "00" * 32 }
    id 0
    payment_preimage { r }

    initialize_with do
      new(Lightning::Wire::LightningMessages::UpdateFulfillHtlc[channel_id, id, payment_preimage])
    end
  end
end

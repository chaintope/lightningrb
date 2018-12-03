# frozen_string_literal: true

FactoryBot.define do
  factory(:update_fail_htlc, class: 'FactoryBotWrapper') do
    channel_id { "00" * 32 }
    id 0
    len 0
    reason ''

    initialize_with do
      new(Lightning::Wire::LightningMessages::UpdateFailHtlc[channel_id, id, len, reason])
    end
  end
end

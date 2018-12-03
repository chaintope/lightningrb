# frozen_string_literal: true

FactoryBot.define do
  factory(:update_fee, class: 'FactoryBotWrapper') do
    channel_id { "\x00" * 32 }
    feerate_per_kw 100

    initialize_with do
      new(Lightning::Wire::LightningMessages::UpdateFee[channel_id, feerate_per_kw])
    end
  end
end
